#!/usr/bin/env bash
# ==========================================================
# backup.sh — Automated Backup System
# Features:
#   • Daily, Weekly, Monthly backup rotation
#   • Dry-run mode
#   • Restore functionality
#   • Logging system
#   • Safe directory creation
# ==========================================================

set -euo pipefail

# === PATHS ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/backup.log"
BACKUP_DIR="$SCRIPT_DIR/backups"
RESTORE_DIR="$SCRIPT_DIR/restore"
DAILY_DIR="$BACKUP_DIR/daily"
WEEKLY_DIR="$BACKUP_DIR/weekly"
MONTHLY_DIR="$BACKUP_DIR/monthly"

# === CONFIGURATION ===
DAILY_KEEP=7
WEEKLY_KEEP=4
MONTHLY_KEEP=3

# === LOGGING FUNCTION ===
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# === PREPARE DIRECTORIES (Safe) ===
for dir in "$BACKUP_DIR" "$DAILY_DIR" "$WEEKLY_DIR" "$MONTHLY_DIR" "$RESTORE_DIR"; do
  if [[ ! -d "$dir" ]]; then
    mkdir -p "$dir"
    log "Created directory: $dir"
  fi
done

# === ARGUMENT PARSING ===
DRYRUN=false

if [[ "${1:-}" == "--dry-run" ]]; then
  DRYRUN=true
  shift
fi

if [[ "${1:-}" == "--list" ]]; then
  echo "=== Available Backups ==="
  tree -h "$BACKUP_DIR" || echo "No backups found."
  exit 0
fi

if [[ "${1:-}" == "--restore" ]]; then
  BACKUP_FILE="$2"
  shift 2
  RESTORE_TARGET="${1:-$RESTORE_DIR}"
  log "Restoring $BACKUP_FILE → $RESTORE_TARGET"
  mkdir -p "$RESTORE_TARGET"
  if [[ "$DRYRUN" == "true" ]]; then
    log "[DRYRUN] Would extract $BACKUP_FILE into $RESTORE_TARGET"
  else
    tar -xzf "$BACKUP_FILE" -C "$RESTORE_TARGET"
    log "Restore completed successfully!"
  fi
  exit 0
fi

# === VALIDATE INPUT ===
if [[ $# -lt 1 ]]; then
  echo "Usage: $0 [--dry-run|--list|--restore <file> --to <folder>] <source_dir>"
  exit 1
fi

SOURCE="$1"
if [[ ! -d "$SOURCE" ]]; then
  echo "Error: Source directory not found: $SOURCE"
  exit 1
fi

# === BACKUP CREATION ===
TIMESTAMP="$(date '+%Y-%m-%d_%H-%M-%S')"
BACKUP_NAME="backup-${TIMESTAMP}.tar.gz"
DAILY_PATH="$DAILY_DIR/$BACKUP_NAME"

log "Starting backup for: $SOURCE"
if [[ "$DRYRUN" == "true" ]]; then
  log "[DRYRUN] Would create: $DAILY_PATH"
else
  tar -czf "$DAILY_PATH" -C "$(dirname "$SOURCE")" "$(basename "$SOURCE")"
  log "Backup created: $DAILY_PATH"
fi

# === ORGANIZE BACKUPS ===
DAY_OF_WEEK=$(date +%u)   # 1=Monday, 7=Sunday
DAY_OF_MONTH=$(date +%d)  # 01-31

# Weekly (Sunday)
if [[ "$DAY_OF_WEEK" == "7" ]]; then
  WEEKLY_PATH="$WEEKLY_DIR/backup-weekly-${TIMESTAMP}.tar.gz"
  log "It's Sunday → marking as weekly backup."
  if [[ "$DRYRUN" == "true" ]]; then
    log "[DRYRUN] Would copy to $WEEKLY_PATH"
  else
    cp "$DAILY_PATH" "$WEEKLY_PATH"
  fi
fi

# Monthly (First day)
if [[ "$DAY_OF_MONTH" == "01" ]]; then
  MONTHLY_PATH="$MONTHLY_DIR/backup-monthly-${TIMESTAMP}.tar.gz"
  log "It's the first of the month → marking as monthly backup."
  if [[ "$DRYRUN" == "true" ]]; then
    log "[DRYRUN] Would copy to $MONTHLY_PATH"
  else
    cp "$DAILY_PATH" "$MONTHLY_PATH"
  fi
fi

# === CLEANUP FUNCTION ===
cleanup_old() {
  local dir="$1"
  local keep="$2"
  local count
  count=$(ls -1t "$dir"/*.tar.gz 2>/dev/null | wc -l || true)
  if (( count > keep )); then
    local delete_count=$((count - keep))
    log "Cleaning up $delete_count old backups in $dir ..."
    ls -1t "$dir"/*.tar.gz | tail -n "$delete_count" | while read -r oldfile; do
      if [[ "$DRYRUN" == "true" ]]; then
        log "[DRYRUN] Would delete $oldfile"
      else
        rm -f "$oldfile"
        log "Deleted old backup: $oldfile"
      fi
    done
  fi
}

# === CLEANUP OLD BACKUPS ===
cleanup_old "$DAILY_DIR" "$DAILY_KEEP"
cleanup_old "$WEEKLY_DIR" "$WEEKLY_KEEP"
cleanup_old "$MONTHLY_DIR" "$MONTHLY_KEEP"

log "Backup process completed successfully ✅"
exit 0
