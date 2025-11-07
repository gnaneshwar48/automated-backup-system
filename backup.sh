#!/usr/bin/env bash
# ============================================================
# backup.sh — Automated Backup Script (Daily/Weekly/Monthly)
# Author: Gnaneshwar Reddy
# Version: 3.0 (2025-11-07)
# Description:
#   Creates compressed backups of a given folder, organizes them
#   into daily/weekly/monthly folders, and cleans up old backups.
# ============================================================

set -euo pipefail

# === PATHS ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/backup.log"
BACKUP_DIR="$SCRIPT_DIR/backups"
RESTORE_DIR="$SCRIPT_DIR/restore"
DAILY_DIR="$BACKUP_DIR/daily"
WEEKLY_DIR="$BACKUP_DIR/weekly"
MONTHLY_DIR="$BACKUP_DIR/monthly"
LOCK_FILE="$SCRIPT_DIR/.backup.lock"

# === CONFIG ===
DAILY_KEEP=7
WEEKLY_KEEP=4
MONTHLY_KEEP=3

# === PREPARE DIRECTORIES ===
mkdir -p "$DAILY_DIR" "$WEEKLY_DIR" "$MONTHLY_DIR" "$RESTORE_DIR"

# === LOGGING FUNCTION ===
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# === CLEANUP LOCK ON EXIT ===
cleanup_lock() {
  [[ -f "$LOCK_FILE" ]] && rm -f "$LOCK_FILE"
}
trap cleanup_lock EXIT

# === LOCK CHECK ===
if [[ -f "$LOCK_FILE" ]]; then
  log "ERROR: Another backup process is running."
  exit 1
fi
touch "$LOCK_FILE"

# === ARGUMENT PARSING ===
DRYRUN=false
ACTION="backup"
SOURCE=""
BACKUP_FILE=""
RESTORE_TARGET="$RESTORE_DIR"

# Handle flags
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRYRUN=true
      shift
      ;;
    --list)
      ACTION="list"
      shift
      ;;
    --restore)
      ACTION="restore"
      BACKUP_FILE="$2"
      shift 2
      ;;
    --to)
      RESTORE_TARGET="$2"
      shift 2
      ;;
    *)
      SOURCE="$1"
      shift
      ;;
  esac
done

# === ACTION: LIST ===
if [[ "$ACTION" == "list" ]]; then
  echo "=== Available Backups ==="
  if command -v tree &>/dev/null; then
    tree -h "$BACKUP_DIR" || echo "No backups found."
  else
    find "$BACKUP_DIR" -type f -name "*.tar.gz" | sort
  fi
  exit 0
fi

# === ACTION: RESTORE ===
if [[ "$ACTION" == "restore" ]]; then
  if [[ -z "$BACKUP_FILE" ]]; then
    log "ERROR: No backup file specified for restore."
    exit 1
  fi

  if [[ ! -f "$BACKUP_FILE" ]]; then
    log "ERROR: Backup file not found: $BACKUP_FILE"
    exit 1
  fi

  mkdir -p "$RESTORE_TARGET"
  log "Restoring from $BACKUP_FILE → $RESTORE_TARGET"

  if [[ "$DRYRUN" == "true" ]]; then
    log "[DRYRUN] Would extract $BACKUP_FILE into $RESTORE_TARGET"
  else
    tar -xzf "$BACKUP_FILE" -C "$RESTORE_TARGET"
    log "Restore completed successfully."
  fi
  exit 0
fi

# === ACTION: BACKUP ===
if [[ -z "$SOURCE" ]]; then
  echo "Usage:"
  echo "  $0 [--dry-run] <source_dir>"
  echo "  $0 --list"
  echo "  $0 --restore <backup_file> [--to <target_dir>]"
  exit 1
fi

if [[ ! -d "$SOURCE" ]]; then
  log "ERROR: Source directory not found: $SOURCE"
  exit 1
fi

TIMESTAMP="$(date '+%Y-%m-%d_%H-%M-%S')"
BACKUP_NAME="backup-${TIMESTAMP}.tar.gz"
DAILY_PATH="$DAILY_DIR/$BACKUP_NAME"

log "Starting backup for $SOURCE ..."
if [[ "$DRYRUN" == "true" ]]; then
  log "[DRYRUN] Would create: $DAILY_PATH"
else
  tar -czf "$DAILY_PATH" -C "$(dirname "$SOURCE")" "$(basename "$SOURCE")"
  log "Backup created: $DAILY_PATH"
fi

# === ORGANIZE BACKUPS ===
DAY_OF_WEEK=$(date +%u)   # 1=Monday, 7=Sunday
DAY_OF_MONTH=$(date +%d)  # 01–31

if [[ "$DAY_OF_WEEK" == "7" ]]; then
  WEEKLY_PATH="$WEEKLY_DIR/backup-weekly-${TIMESTAMP}.tar.gz"
  log "It's Sunday → marking as weekly backup."
  [[ "$DRYRUN" == "true" ]] && log "[DRYRUN] Would copy to $WEEKLY_PATH" || cp "$DAILY_PATH" "$WEEKLY_PATH"
fi

if [[ "$DAY_OF_MONTH" == "01" ]]; then
  MONTHLY_PATH="$MONTHLY_DIR/backup-monthly-${TIMESTAMP}.tar.gz"
  log "It's the first of the month → marking as monthly backup."
  [[ "$DRYRUN" == "true" ]] && log "[DRYRUN] Would copy to $MONTHLY_PATH" || cp "$DAILY_PATH" "$MONTHLY_PATH"
fi

# === CLEANUP OLD BACKUPS ===
cleanup_old() {
  local dir="$1"
  local keep="$2"
  local files
  IFS=$'\n' read -r -d '' -a files < <(ls -1t "$dir"/*.tar.gz 2>/dev/null || true; printf '\0')
  local count="${#files[@]}"

  if (( count > keep )); then
    local delete_count=$((count - keep))
    log "Cleaning up $delete_count old backups in $dir ..."
    for oldfile in "${files[@]: -delete_count}"; do
      [[ "$DRYRUN" == "true" ]] && log "[DRYRUN] Would delete $oldfile" || rm -f "$oldfile"
    done
  fi
}

cleanup_old "$DAILY_DIR" "$DAILY_KEEP"
cleanup_old "$WEEKLY_DIR" "$WEEKLY_KEEP"
cleanup_old "$MONTHLY_DIR" "$MONTHLY_KEEP"

log "✅ Backup finished successfully!"
