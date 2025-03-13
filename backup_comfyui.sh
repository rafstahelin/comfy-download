#!/bin/bash

# Script to backup ComfyUI default user folder to Dropbox
# Usage: backup_comfyui.sh [force]
# If "force" parameter is provided, backup will run regardless of last backup time

# Source directory to backup
SOURCE_DIR="/workspace/ComfyUI/user/default"
# Destination directory on Dropbox
DEST_DIR="dbx:/studio/ai/libs/comfy-data/bckp-runpod-default"
# Logs directory
LOGS_DIR="/workspace/ComfyUI/logs"
# Temporary directory for zip files
TEMP_DIR="/tmp/comfyui-backup"

# Create necessary directories
mkdir -p "$LOGS_DIR"
mkdir -p "$TEMP_DIR"

# Current timestamp
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
# Zip filename with timestamp
ZIP_FILENAME="default-$TIMESTAMP.zip"
# Full path to zip file
ZIP_FILE="$TEMP_DIR/$ZIP_FILENAME"
# Log file for backup operations
BACKUP_LOG="$LOGS_DIR/backup.log"

# Check if we should force backup
FORCE_BACKUP=0
if [ "$1" == "force" ]; then
  FORCE_BACKUP=1
fi

# Function to log messages
log_message() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$BACKUP_LOG"
  echo "$1"
}

# Check if source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
  log_message "ERROR: Source directory $SOURCE_DIR does not exist"
  exit 1
fi

# Check if backup is needed
if [ $FORCE_BACKUP -eq 0 ]; then
  # Check last backup time from log
  LAST_BACKUP=$(grep "Backup complete" "$BACKUP_LOG" 2>/dev/null | tail -1 | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{2}')
  
  if [ ! -z "$LAST_BACKUP" ]; then
    # Extract date and hour from last backup
    LAST_DATE=${LAST_BACKUP:0:10}
    LAST_HOUR=${LAST_BACKUP:11:2}
    
    # Get current date and hour
    CURRENT_DATE=$(date +%Y-%m-%d)
    CURRENT_HOUR=$(date +%H)
    
    # If backup was done in the same hour and date, skip
    if [ "$LAST_DATE" == "$CURRENT_DATE" ] && [ "$LAST_HOUR" == "$CURRENT_HOUR" ]; then
      log_message "Skipping backup - already performed in this hour"
      exit 0
    fi
  fi
fi

# Start backup process
log_message "Starting backup of $SOURCE_DIR"

# Create zip file
log_message "Creating zip file $ZIP_FILE"
if ! zip -r "$ZIP_FILE" "$SOURCE_DIR"; then
  log_message "ERROR: Failed to create zip file"
  exit 1
fi

# Get size of zip file
ZIP_SIZE=$(du -h "$ZIP_FILE" | cut -f1)
log_message "Zip file created successfully ($ZIP_SIZE)"

# Upload to Dropbox using rclone
log_message "Uploading to Dropbox at $DEST_DIR"
if ! rclone copy "$ZIP_FILE" "$DEST_DIR"; then
  log_message "ERROR: Failed to upload to Dropbox"
  exit 1
fi

log_message "Backup complete: $ZIP_FILENAME uploaded to Dropbox"

# Clean up temporary zip file
log_message "Cleaning up temporary files"
rm -f "$ZIP_FILE"

exit 0