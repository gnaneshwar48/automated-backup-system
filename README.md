# Automated Backup System (Bash Script)


## A. Project Overview
This Bash script automatically creates compressed backups of folders, verifies them, and removes older backups to save space. It is configurable, safe, and easy to use.


## B. How to Use It


1️⃣ Setup

Clone or download this project.

Open the folder:

cd backup-system

Make the script executable:

chmod +x backup.sh

2️⃣ Edit Configuration

Open the file backup.config and set:

BACKUP_DESTINATION=/home/user/backups
EXCLUDE_PATTERNS=".git,node_modules,.cache"
DAILY_KEEP=7
WEEKLY_KEEP=4
MONTHLY_KEEP=3

3️⃣ Run Backup
./backup.sh /path/to/folder


This will create a backup file like:

backup-2025-11-03-1430.tar.gz


and a checksum file:

backup-2025-11-03-1430.tar.gz.md5

4️⃣ Other Commands

Dry run (test mode)

./backup.sh --dry-run /path/to/folder


→ Shows what will happen without doing it.

List all backups

./backup.sh --list


Restore a backup

./backup.sh --restore /home/backups/backup-2025-11-03-1430.tar.gz --to /home/user/restore_folder

🧾 Log File

All activities are saved in:

backup.log


Example:

[2025-11-03 14:30:15] INFO: Starting backup of /home/user/documents
[2025-11-03 14:30:45] SUCCESS: Backup created successfully
[2025-11-03 14:30:46] INFO: Checksum verified

🧹 Automatic Cleanup

The script keeps only:

Last 7 daily backups

Last 4 weekly backups

Last 3 monthly backups
Older backups are deleted automatically.

⚠️ Error Handling

The script shows clear error messages if:

Folder doesn’t exist

No permission to read folder

Not enough space

Config file missing

✅ Example Output
[2025-11-03 14:30:15] INFO: Starting backup of /home/user/documents
[2025-11-03 14:30:45] SUCCESS: Backup created: backup-2025-11-03-1430.tar.gz
[2025-11-03 14:30:46] INFO: Checksum verified successfully

🏁 That’s It!

Just run the script regularly (or add to cron) to keep your files safe automatically.
