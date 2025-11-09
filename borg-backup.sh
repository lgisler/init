#!/bin/bash

set -euxo pipefail

# Configuration (need to change)
SOURCE_DIR="/path/to/source/directory"
BORG_REPO="/path/to/borg/repo"
RCLONE_REMOTE="remote:path/to/backup"

# Configuration (defaults)
BACKUP_NAME=$(date +%Y-%m-%d_%H%M%S)
LOG_DIR="/path/to/logs"
LOG_FILE="$LOG_DIR/$BACKUP_NAME.log"

# Optional:
# export BORG_PASSPHRASE="add-your-borg-repo-password-here"

# log output (useful for automation)
mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_FILE") 2>&1

show_help() {
	cat <<EOF
Usage: $0 {--init|--backup|--upload|--help}

Commands:
  --init      Initialize new borg repository with encryption
  --backup    Create backup of source directory to borg repo
  --upload    Upload borg repository to remote storage via rclone
  --setup-cron  Setup cron job to run backup and upload at 3:30am daily
  --help  Show this help message

Configuration:
  SOURCE_DIR:    $SOURCE_DIR
  BORG_REPO:     $BORG_REPO
  RCLONE_REMOTE: $RCLONE_REMOTE

Examples:
  $0 --init                    # Initialize repository
  $0 --backup                  # Create backup
  $0 --upload                  # Upload to remote
  $0 --setup-cron              # Setup automated daily backups
  $0 --backup && $0 --upload   # Backup and upload
EOF
}

init_repo() {
	if [ -d "$BORG_REPO/data" ]; then
		echo "Repository already initialized at: $BORG_REPO"
		exit 0
	fi

	echo "Initializing borg repository..."
	borg init --encryption=repokey-blake2 "$BORG_REPO"

	echo "Exporting borg key..."
	borg key export "$BORG_REPO" encrypted-key-backup

	echo "Done. Repository initialized at: $BORG_REPO"
	echo "Key exported to: encrypted-key-backup"
	echo "BACKUP THIS KEY FILE TO SEPARATE LOCATION"
}

backup_data() {
	if [ ! -d "$BORG_REPO/data" ]; then
		echo "Repository not initialized. Run with --init first"
		exit 1
	fi

	# Dump postgres database
	echo "Backing up postgres database..."
	docker exec -t immich_postgres pg_dumpall --clean --if-exists --username=postgres >"$SOURCE_DIR"/database-backup/immich-database.sql

	echo "Creating backup: $BACKUP_NAME"
	borg create --progress --stats --compression lz4 \
		"$BORG_REPO::$BACKUP_NAME" \
		"$SOURCE_DIR" \
		--exclude "$SOURCE_DIR/thumbs/" \
		--exclude "$SOURCE_DIR/encoded-video/"

	echo "Pruning old backups..."
	borg prune "$BORG_REPO" --keep-daily=7 --keep-weekly=4 --keep-monthly=6

	echo "Compacting repository..."
	borg compact "$BORG_REPO"

	echo "Backup complete"
}

upload_to_remote() {
	if [ ! -d "$BORG_REPO/data" ]; then
		echo "Repository data not found at: $BORG_REPO/data"
		exit 1
	fi

	echo "Uploading to rclone remote..."
	rclone sync "$BORG_REPO" "$RCLONE_REMOTE" \
		--progress \
		--transfers 4 \
		--retries 10 \
		--low-level-retries 10 \
		--tpslimit 5

	echo "Upload complete"
}

setup_cron() {
	SCRIPT_PATH="$(readlink -f "$0")"
	CRON_JOB="30 3 * * * $SCRIPT_PATH --backup && $SCRIPT_PATH --upload"

	# Check if cron job already exists
	if crontab -l 2>/dev/null | grep -F "$SCRIPT_PATH" >/dev/null 2>&1; then
		echo "Cron job already exists for this script"
		crontab -l | grep -F "$SCRIPT_PATH"
		exit 0
	fi

	# Add cron job
	(
		crontab -l 2>/dev/null || true
		echo "$CRON_JOB"
	) | crontab -

	echo "Cron job added successfully:"
	echo "$CRON_JOB"
	echo ""
	echo "Backup and upload will run daily at 3:30 AM"
}

# Parse arguments
case "${1:-}" in
--init)
	init_repo
	;;
--backup)
	backup_data
	;;
--upload)
	upload_to_remote
	;;
--setup-cron)
	setup_cron
	;;
-h | --help | "")
	show_help
	;;
*)
	echo "Error: Unknown option '$1'"
	echo ""
	show_help
	exit 1
	;;
esac
