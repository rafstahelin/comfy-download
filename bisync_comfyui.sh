#!/bin/bash

# Script to perform bidirectional sync of ComfyUI settings with Dropbox
# Usage: bisync_comfyui.sh [force]
# If "force" parameter is provided, sync will run with --force option

# Source directory to sync
SOURCE_DIR="/workspace/ComfyUI/user/default"

# Destination directory on Dropbox (UPDATED TO CORRECT PATH)
DEST_DIR="dbx:/studio/ai/libs/comfy-data/default"

# Logs directory
LOGS_DIR="/workspace/ComfyUI/logs"
BISYNC_LOG="$LOGS_DIR/bisync.log"
ERROR_LOG="$LOGS_DIR/bisync_error.log"

# Create necessary directories
mkdir -p "$LOGS_DIR"
mkdir -p "$SOURCE_DIR"
mkdir -p "$SOURCE_DIR/workflows"

# Check if we should force sync
FORCE_FLAG=""
if [ "$1" == "force" ]; then
  FORCE_FLAG="--force"
fi

# Function to log messages
log_message() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$BISYNC_LOG"
  echo "$1"
}

# Start sync process
log_message "Starting bidirectional sync for ComfyUI user settings"

# First, check if rclone can access the Dropbox
log_message "Testing Dropbox connectivity..."
if ! rclone lsd dbx: > /dev/null 2>&1; then
  log_message "ERROR: Cannot access Dropbox. Please check rclone configuration with 'rclone config'."
  exit 1
fi

# Create a filter file to only sync specific files and folders
# UPDATED: Added exclusion for ComfyUI-Manager directory
FILTER_FILE="/tmp/comfy_bisync_filter.txt"
cat > "$FILTER_FILE" << EOF
+ /comfy.templates.json
+ /comfy.settings.json
+ /workflows/**
- /ComfyUI-Manager/**
- *
EOF

# Set default timeout and transfer settings
TIMEOUT_FLAG="--timeout=30m"
TRANSFER_FLAGS="--transfers=4 --checkers=8"

# Check for large workflow files and adjust settings if needed
if [ -d "$SOURCE_DIR/workflows" ]; then
  TOTAL_SIZE=$(du -sm "$SOURCE_DIR/workflows" | cut -f1)
  
  if [ $TOTAL_SIZE -gt 50 ]; then
    log_message "WARNING: Workflows directory is quite large ($TOTAL_SIZE MB), sync may take longer"
    
    # Adjust settings for larger directories
    TIMEOUT_FLAG="--timeout=2h"
    TRANSFER_FLAGS="--transfers=4 --checkers=16 --max-backlog=10000"
    
    # With large directories, first ensure destination exists
    log_message "Ensuring destination directory exists..."
    rclone mkdir "$DEST_DIR" >> "$BISYNC_LOG" 2>&1
    rclone mkdir "$DEST_DIR/workflows" >> "$BISYNC_LOG" 2>&1
    
    # Check if workflows directory exists on remote
    if ! rclone lsd "$DEST_DIR/workflows" > /dev/null 2>&1; then
      log_message "Workflows directory doesn't exist on remote. Initial sync may take a while..."
      
      # For large directories with no remote equivalent, suggest staged approach
      if [ $TOTAL_SIZE -gt 80 ]; then
        log_message "Directory is very large ($TOTAL_SIZE MB). Consider running initial sync in stages manually:"
        log_message "1. First sync settings files: rclone copy $SOURCE_DIR/comfy*.json $DEST_DIR/ --progress"
        log_message "2. Then sync workflows in batches or smaller folders"
      fi
    fi
  fi
fi

# Make sure the directories and files exist on both sides
log_message "Ensuring directories exist on both sides..."

# Ensure remote directories exist
rclone mkdir "$DEST_DIR" >> "$BISYNC_LOG" 2>&1
rclone mkdir "$DEST_DIR/workflows" >> "$BISYNC_LOG" 2>&1

# Ensure local files exist (create empty if not)
touch "$SOURCE_DIR/comfy.templates.json" 2>/dev/null
touch "$SOURCE_DIR/comfy.settings.json" 2>/dev/null

# Perform sync for each component separately for more robustness
log_message "Syncing settings file..."
rclone copy "$SOURCE_DIR/comfy.settings.json" "$DEST_DIR/" $TIMEOUT_FLAG --verbose >> "$BISYNC_LOG" 2>&1

log_message "Syncing templates file..."
rclone copy "$SOURCE_DIR/comfy.templates.json" "$DEST_DIR/" $TIMEOUT_FLAG --verbose >> "$BISYNC_LOG" 2>&1

log_message "Checking for newer remote files to download first..."
# FIX: Make sure we get clean integers without newlines
NEWER_SETTINGS=$(rclone --no-modtime check "$SOURCE_DIR/comfy.settings.json" "$DEST_DIR/comfy.settings.json" 2>&1 | grep -c "differ" || echo "0")
NEWER_TEMPLATES=$(rclone --no-modtime check "$SOURCE_DIR/comfy.templates.json" "$DEST_DIR/comfy.templates.json" 2>&1 | grep -c "differ" || echo "0") 

# FIX: Trim whitespace and ensure we have clean integers
NEWER_SETTINGS=$(echo $NEWER_SETTINGS | tr -d '[:space:]')
NEWER_TEMPLATES=$(echo $NEWER_TEMPLATES | tr -d '[:space:]')

# FIX: Default to 0 if not a number
if ! [[ "$NEWER_SETTINGS" =~ ^[0-9]+$ ]]; then
  NEWER_SETTINGS=0
fi

if ! [[ "$NEWER_TEMPLATES" =~ ^[0-9]+$ ]]; then
  NEWER_TEMPLATES=0
fi

log_message "Settings differences: $NEWER_SETTINGS, Templates differences: $NEWER_TEMPLATES"

if [ "$NEWER_SETTINGS" -gt 0 ]; then
  log_message "Remote settings file differs, downloading..."
  rclone copy "$DEST_DIR/comfy.settings.json" "$SOURCE_DIR/" $TIMEOUT_FLAG --verbose >> "$BISYNC_LOG" 2>&1
fi

if [ "$NEWER_TEMPLATES" -gt 0 ]; then
  log_message "Remote templates file differs, downloading..."
  rclone copy "$DEST_DIR/comfy.templates.json" "$SOURCE_DIR/" $TIMEOUT_FLAG --verbose >> "$BISYNC_LOG" 2>&1
fi

# Now perform the bidirectional sync for workflows
log_message "Performing bidirectional sync for workflows directory..."
# Store detailed error output separately
rm -f "$ERROR_LOG" 2>/dev/null

# UPDATED: Always exclude ComfyUI-Manager and hidden files/directories
EXCLUDE_FLAGS="--exclude ComfyUI-Manager/** --exclude '.*/**' --exclude '*/\.*'"
log_message "Excluding ComfyUI-Manager directory and hidden files from sync"

# Execute the bisync command with all our flags
rclone bisync "$SOURCE_DIR/workflows" "$DEST_DIR/workflows" $FORCE_FLAG $TIMEOUT_FLAG $TRANSFER_FLAGS $EXCLUDE_FLAGS --verbose > "$ERROR_LOG" 2>&1

if [ $? -eq 0 ]; then
  log_message "Bidirectional sync completed successfully"
  cat "$ERROR_LOG" >> "$BISYNC_LOG"
else
  # If sync failed, try again with resync option
  log_message "Workflows sync failed, attempting with --resync option"
  rclone bisync "$SOURCE_DIR/workflows" "$DEST_DIR/workflows" --force --resync $TIMEOUT_FLAG $TRANSFER_FLAGS $EXCLUDE_FLAGS --verbose > "$ERROR_LOG" 2>&1
  
  if [ $? -eq 0 ]; then
    log_message "Bidirectional sync completed successfully with resync"
    cat "$ERROR_LOG" >> "$BISYNC_LOG"
  else
    # Try one more time with minimal operations for recovery
    log_message "Resync failed, attempting final recovery with minimal operations..."
    rclone bisync "$SOURCE_DIR/workflows" "$DEST_DIR/workflows" --force --resync $TIMEOUT_FLAG --max-delete 0 $EXCLUDE_FLAGS --verbose > "$ERROR_LOG" 2>&1
    
    if [ $? -eq 0 ]; then
      log_message "Minimal recovery sync completed successfully"
      cat "$ERROR_LOG" >> "$BISYNC_LOG"
    else
      log_message "ERROR: Bidirectional sync failed completely. Check details below:"
      cat "$ERROR_LOG" >> "$BISYNC_LOG"
      # Extract error message for log
      ERROR_MSG=$(grep -A 5 "ERROR" "$ERROR_LOG" 2>/dev/null | head -6)
      log_message "Error details: ${ERROR_MSG}"
    fi
  fi
fi

# Clean up
rm -f "$FILTER_FILE"
rm -f "$ERROR_LOG" 2>/dev/null

log_message "Bidirectional sync process finished"

exit 0