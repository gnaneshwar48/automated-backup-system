# Project Name : Automated Backup System
Project Overview :

The Automated Backup System is a Bash-based utility that automatically creates compressed backups, verifies their integrity, and cleans up older backups using configurable retention rules. It is designed to run safely, efficiently, and reliably — ideal for developers, system administrators, or anyone who needs automated file backups on Linux/macOS.

This project helps prevent data loss by:

Automatically creating timestamped backups
Verifying backup integrity using checksums
Managing backup retention (daily, weekly, monthly)
Logging every operation for full traceability

Create timestamped .tar.gz backups :

Automatically skip unwanted folders (like .git, node_modules, .cache)
Generate checksum (.sha256) for integrity verification
Delete old backups based on daily/weekly/monthly rules
Dry-run mode (simulate actions without changing anything)
Prevent multiple script runs using lock files
Restore from any backup archive
Comprehensive logging system (backup.log)
Configurable via backup.config file

# Project Structure:

backup-system/
├── backup.sh              # Main script
├── backup.config          # Configuration file
├── README.md              # Documentation
├── logs/
│   └── backup.log         # Activity logs
├── backups/
│   ├── daily/
│   ├── weekly/
│   └── monthly/
└── test_data/             # Sample data for testing

Configuration File (backup.config) :

Customize all settings here — no need to modify the script itself.
# Backup destination folder
BACKUP_DESTINATION=./backups

# Exclude these folders/files from backups
EXCLUDE_PATTERNS=".git,node_modules,.cache"

# Retention policy
DAILY_KEEP=7
WEEKLY_KEEP=4
MONTHLY_KEEP=3

# Optional email for notifications (not implemented yet)
EMAIL_NOTIFICATION=""

How it Works :
1. Create Backups
When you run:
./backup.sh /path/to/folder
The script:
Checks if another instance is already running (via /tmp/backup.lock).
Reads backup.config for settings.
Creates a .tar.gz file named like:
backup-2025-11-07-1030.tar.gz
Generates a .sha256 checksum file.
Logs all actions to logs/backup.log.

2. Verify Backup :
After creation, the script re-checks the checksum file to confirm that:
The archive was created correctly.
The file hasn’t been corrupted.

3.Retention Policy: 
To save disk space, the script deletes old backups automatically:
Keeps last 7 daily backups
Keeps last 4 weekly backups
Keeps last 3 monthly backups
Anything older is safely removed, and the cleanup is logged.

4. Logging: 
All actions are logged in:
logs/backup.log

Example: 
[2025-11-07 10:30:15] INFO: Starting backup of /home/user/documents
[2025-11-07 10:30:45] SUCCESS: Backup created: backup-2025-11-07-1030.tar.gz
[2025-11-07 10:30:46] INFO: Checksum verified successfully
[2025-11-07 10:31:10] INFO: Deleted old backup: backup-2025-10-01-0830.tar.gz

# Usage Examples :
1. Create Backups:
./backup.sh /home/user/documents

2. Dry Run (Preview Actions)
./backup.sh --dry-run /home/user/documents

OutPut:
Would backup folder: /home/user/documents
Would skip: .git, node_modules, .cache
Would create: backup-2025-11-07-1030.tar.gz
Would delete: backup-2025-10-01-0900.tar.gz

3. Restore a backup:
./backup.sh --restore backups/backup-2025-11-07-1030.tar.gz --to ./restored_files

4. list backups
ls -lh backups/

Error Handling
The script gracefully handles all common errors:
| Situation                | Message                                        |
| ------------------------ | ---------------------------------------------- |
| Folder doesn’t exist     | `ERROR: Source folder not found`               |
| No read permission       | `ERROR: Cannot read folder, permission denied` |
| Config missing           | `ERROR: Configuration file not found`          |
| Not enough space         | `ERROR: Not enough disk space for backup`      |
| Another instance running | `ERROR: Another backup process is running`     |
| Interrupted backup       | Partial backups cleaned up automatically       |


# Testing Instructions

1. Create a test folder:
mkdir -p test_data/documents
echo "Sample File" > test_data/documents/file1.txt

2.Run a backup:
./backup.sh test_data

3.Create multiple backups(simulate days):
touch -d "7 days ago" backups/backup-2025-10-31-0830.tar.gz

4.Check auto-cleanup logs.

5.Test restoration: 
./backup.sh --restore backups/backup-2025-11-07-1030.tar.gz --to ./restore

6. Test dry-run mode to preview actions.

# Rotation Algorithm Explained

The script identifies old backups by timestamp in filenames:
backup-YYYY-MM-DD-HHMM.tar.gz

Then:
1.Sorts all backups by date.
2.Keeps the most recent N (daily), N (weekly), and N (monthly) according to config.
3.Deletes the rest, ensuring minimum space usage while preserving history.

Checksum Verification:

Every backup file has a matching .sha256 file generated via:
sha256sum backup-2025-11-07-1030.tar.gz > backup-2025-11-07-1030.tar.gz.sha256

# During Verification :
sha256sum -c backup-2025-11-07-1030.tar.gz.sha256
If the result is OK, integrity is confirmed.

# Design Decisions:
1.Bash chosen for portability and simplicity.
2.Tar + gzip provides efficient compression and easy restore.
3.SHA256 checksums ensure data integrity.
4.Lock file prevents accidental double runs.
5.Config file separates logic from settings, making it user-friendly.
6.Logs provide full audit trail of backups and deletions.

# Known Limitations:
No email notifications (can be added with mail or sendmail)
No incremental backup feature (only full backups for now)
Works best on Linux/macOS — not natively tested on Windows PowerShell

# Future Improvements:
Add email notification system
Add incremental backups using rsync
Add remote upload (e.g., AWS S3, Google Drive)
Add GUI dashboard

# Conclusion:
This project provides a reliable, configurable, and easy-to-use backup automation system.
It helps maintain organized, verified backups while saving time and storage space.





