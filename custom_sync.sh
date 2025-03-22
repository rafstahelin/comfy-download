#!/bin/bash

# Script to perform bidirectional sync of custom node data directories with Dropbox
# Usage: custom_sync.sh [force]
# If "force" parameter is provided, sync will run with --force option

# Logs directory
LOGS_DIR="/workspace/ComfyUI/logs"
SYNC_LOG="$LOGS_DIR/custom_sync.log"
ERROR_LOG="$LOGS_DIR/custom_sync_error.log"

# Create necessary directories
mkdir -p "$LOGS_DIR"
mkdir -p "/workspace/comfy-data/milehighstyler"
mkdir -p "/workspace/comfy-data/plushparameters"
mkdir -p "/workspace/comfy-data/plushprompts"

# Configuration
SOURCE_DIRS=(
  "/workspace/comfy-data/milehighstyler"
  "/workspace/comfy-data/plushparameters"
  "/workspace/comfy-data/plushprompts"
)

DEST_DIRS=(
  "dbx:/studio/ai/libs/comfy-data/milehighstyler"
  "dbx:/studio/ai/libs/comfy-data/plushparameters"
  "dbx:/studio/ai/libs/comfy-data/plushprompts"
)

# Check if we should force sync
FORCE_FLAG=""
if [ "$1" == "force" ]; then
  FORCE_FLAG="--force"
fi

# Function to log messages
log_message() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$SYNC_LOG"
  echo "$1"
}

# Start sync process
log_message "Starting bidirectional sync for custom node data directories"

# First, check if rclone can access the Dropbox
log_message "Testing Dropbox connectivity..."
if ! rclone lsd dbx: > /dev/null 2>&1; then
  log_message "ERROR: Cannot access Dropbox. Please check rclone configuration with 'rclone config'."
  exit 1
fi

# Set default timeout and transfer settings
TIMEOUT_FLAG="--timeout=15m"
TRANSFER_FLAGS="--transfers=4 --checkers=8"

# Function to perform bidirectional sync
sync_directory() {
  local source="$1"
  local dest="$2"
  local dir_name=$(basename "$source")
  
  log_message "Syncing $dir_name directory..."
  
  # Ensure remote directory exists
  rclone mkdir "$dest" >> "$SYNC_LOG" 2>&1
  
  # Execute the bisync command
  rclone bisync "$source" "$dest" $FORCE_FLAG $TIMEOUT_FLAG $TRANSFER_FLAGS --verbose > "$ERROR_LOG" 2>&1
  
  if [ $? -eq 0 ]; then
    log_message "$dir_name bidirectional sync completed successfully"
    cat "$ERROR_LOG" >> "$SYNC_LOG"
    return 0
  else
    # If sync failed, try again with resync option
    log_message "$dir_name sync failed, attempting with --resync option"
    rclone bisync "$source" "$dest" --force --resync $TIMEOUT_FLAG $TRANSFER_FLAGS --verbose > "$ERROR_LOG" 2>&1
    
    if [ $? -eq 0 ]; then
      log_message "$dir_name bidirectional sync completed successfully with resync"
      cat "$ERROR_LOG" >> "$SYNC_LOG"
      return 0
    else
      log_message "ERROR: $dir_name bidirectional sync failed. Check details below:"
      cat "$ERROR_LOG" >> "$SYNC_LOG"
      # Extract error message for log
      ERROR_MSG=$(grep -A 5 "ERROR" "$ERROR_LOG" 2>/dev/null | head -6)
      log_message "Error details: ${ERROR_MSG}"
      return 1
    fi
  fi
}

# Main sync loop
SYNC_SUCCESS=true
for i in "${!SOURCE_DIRS[@]}"; do
  if ! sync_directory "${SOURCE_DIRS[$i]}" "${DEST_DIRS[$i]}"; then
    SYNC_SUCCESS=false
  fi
done

# Clean up
rm -f "$ERROR_LOG" 2>/dev/null

if $SYNC_SUCCESS; then
  log_message "All custom node data directories synchronized successfully"
else
  log_message "WARNING: One or more directory synchronizations failed"
fi

log_message "Custom node data sync process finished"

exit 0