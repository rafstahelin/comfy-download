#!/bin/bash

<<<<<<< HEAD
# ComfyUI Bidirectional Sync Script
# Syncs workflows directory and ComfyUI settings/templates with Dropbox
# Supports content-based comparison for JSON files

# Check if force flag is provided
if [[ "$1" == "force" ]]; then
    force_flag="force"
    shift
else
    force_flag=""
fi

# Default behavior is to sync nothing unless specified
sync_workflows=false
sync_comfy=false
verbose=false

# Parse additional options
for opt in "$@"; do
    case "$opt" in
        --workflows|--workflows-only|wf)
            sync_workflows=true
            ;;
        --comfy|--comfy-only|cf)
            sync_comfy=true
            ;;
        --verbose|-v)
            verbose=true
            ;;
        --all)
            sync_workflows=true
            sync_comfy=true
            ;;
    esac
done

# If no specific option was provided, sync everything
if [[ "$sync_workflows" == "false" && "$sync_comfy" == "false" ]]; then
    sync_workflows=true
    sync_comfy=true
fi

# Log message based on verbosity level
log() {
    local level="$1"
    local message="$2"
    
    case "$level" in
        "debug")
            # Only show debug messages in verbose mode
            if [ "$verbose" = true ]; then
                echo "DEBUG: $message"
            fi
            ;;
        "info")
            echo "$message"
            ;;
        "error")
            echo "ERROR: $message" >&2
            ;;
    esac
}

# Function to sync individual JSON files with content-based comparison
sync_json_file() {
    local local_file="$1"
    local remote_file="$2"
    local file_basename=$(basename "$local_file")
    
    log "debug" "Comparing $file_basename with remote version..."
    
    # Create temporary directory for comparison
    mkdir -p /tmp/sync_compare
    
    # Download remote file
    log "debug" "Downloading remote version for comparison..."
    rclone copy "$(dirname $remote_file)" /tmp/sync_compare/ --include "$(basename $remote_file)" 2>/dev/null
    remote_tmp="/tmp/sync_compare/$(basename $remote_file)"
    
    # If remote file doesn't exist, upload local
    if [ ! -f "$remote_tmp" ]; then
        if [ -f "$local_file" ]; then
            log "info" "$file_basename: Remote file doesn't exist, uploading local version"
            rclone copy "$local_file" "$(dirname $remote_file)" 2>/dev/null
            echo "$file_basename:"
            echo "  Local: $(stat -c "%Y" "$local_file" 2>/dev/null | xargs -I{} date -d @{} '+%Y-%m-%d %H:%M:%S')"
            echo "  Remote: File not found"
            echo "  STATUS: UPLOAD_NEW"
        else
            log "info" "$file_basename: Both files missing"
            echo "$file_basename:"
            echo "  Local: File not found"
            echo "  Remote: File not found"
            echo "  STATUS: MISSING_BOTH"
        fi
        return
    fi
    
    # If local file doesn't exist, download remote
    if [ ! -f "$local_file" ]; then
        log "info" "$file_basename: Local file doesn't exist, downloading remote version"
        rclone copy "$remote_file" "$(dirname $local_file)" 2>/dev/null
        echo "$file_basename:"
        echo "  Local: File not found"
        echo "  Remote: $(stat -c "%Y" "$remote_tmp" 2>/dev/null | xargs -I{} date -d @{} '+%Y-%m-%d %H:%M:%S')"
        echo "  STATUS: DOWNLOAD_NEW"
        return
    fi
    
    # Compare content (checksums)
    local_md5=$(md5sum "$local_file" 2>/dev/null | cut -d' ' -f1)
    remote_md5=$(md5sum "$remote_tmp" 2>/dev/null | cut -d' ' -f1)
    
    # Get modification times
    local_mtime=$(stat -c "%Y" "$local_file" 2>/dev/null)
    remote_mtime=$(stat -c "%Y" "$remote_tmp" 2>/dev/null)
    local_time=$(date -d @$local_mtime '+%Y-%m-%d %H:%M:%S' 2>/dev/null)
    remote_time=$(date -d @$remote_mtime '+%Y-%m-%d %H:%M:%S' 2>/dev/null)
    
    # Output file information for parsing
    echo "$file_basename:"
    echo "  Local: $local_time"
    echo "  Remote: $remote_time"
    
    # Compare content
    if [ "$local_md5" != "$remote_md5" ]; then
        # Content differs - determine which is newer
        if [ "$local_mtime" -gt "$remote_mtime" ]; then
            log "debug" "Local file is newer and different, uploading to remote"
            rclone copy --checksum "$local_file" "$(dirname $remote_file)" 2>/dev/null
            echo "  STATUS: UPLOAD_NEWER"
            
            # Show what changed with a diff in verbose mode
            if [ "$verbose" = true ]; then
                log "debug" "Differences detected:"
                diff -u --color=always "$remote_tmp" "$local_file" | head -n 20
            fi
        else
            log "debug" "Remote file is newer and different, downloading to local"
            rclone copy --checksum "$remote_file" "$(dirname $local_file)" 2>/dev/null
            echo "  STATUS: DOWNLOAD_NEWER"
            
            # Show what changed with a diff in verbose mode
            if [ "$verbose" = true ]; then
                log "debug" "Differences detected:"
                diff -u --color=always "$remote_tmp" "$local_file" | head -n 20
            fi
        fi
    else
        log "debug" "Files are identical, no action needed"
        echo "  STATUS: IN_SYNC"
    fi
    
    # Clean up temp files
    if [ "$verbose" != true ]; then
        rm -f "$remote_tmp" 2>/dev/null
    fi
}

# Function to sync ComfyUI user settings
sync_comfy_settings() {
    log "info" "Starting bidirectional sync for ComfyUI user settings"
    log "debug" "Testing Dropbox connectivity..."
    
    # Define paths
    local_settings="/workspace/ComfyUI/user/default/comfy.settings.json"
    remote_settings="dbx:/studio/ai/libs/comfy-data/default/comfy.settings.json"
    local_templates="/workspace/ComfyUI/user/default/comfy.templates.json"
    remote_templates="dbx:/studio/ai/libs/comfy-data/default/comfy.templates.json"
    
    # Ensure directories exist
    mkdir -p /workspace/ComfyUI/user/default
    
    # Sync each file with content-based comparison
    sync_json_file "$local_settings" "$remote_settings"
    sync_json_file "$local_templates" "$remote_templates"
    
    log "info" "ComfyUI settings sync completed successfully"
}

# Function to sync workflows directory
sync_workflows_dir() {
    log "info" "Performing bidirectional sync for workflows directory..."
    log "debug" "Excluding ComfyUI-Manager directory and hidden files from sync"
    
    # Define workflow paths
    local_workflows="/workspace/ComfyUI/user/default/workflows"
    remote_workflows="dbx:/studio/ai/libs/comfy-data/default/workflows"
    
    # Ensure local directory exists
    mkdir -p "$local_workflows"
    
    # Run actual sync using regular bisync for directory
    extra_flags=""
    if [ "$verbose" = true ]; then
        extra_flags="-v"
    fi
    
    if [ -n "$force_flag" ]; then
        extra_flags="$extra_flags --force"
    fi
    
    # Execute the sync command
    if ! rclone bisync "$local_workflows" "$remote_workflows" $extra_flags --exclude="ComfyUI-Manager/**" --exclude=".*" 2>&1; then
        log "error" "Workflow sync encountered an issue. Try using the --force flag."
        return 1
    fi
    
    log "info" "Bidirectional sync completed successfully"
}

# Main execution
RESULT=0

if [ "$sync_comfy" = true ]; then
    sync_comfy_settings || RESULT=1
fi

if [ "$sync_workflows" = true ]; then
    sync_workflows_dir || RESULT=1
fi

log "info" "Bidirectional sync process finished"
exit $RESULT
=======
# Script to perform bidirectional sync of ComfyUI settings with Dropbox
# Usage: bisync_comfyui.sh [force] [mode]
# If "force" parameter is provided, sync will run with --force option
# Mode can be "workflows", "comfy", or not specified (for everything)

# Parse arguments
FORCE_FLAG=""
MODE="all"

for arg in "$@"; do
  if [ "$arg" == "force" ]; then
    FORCE_FLAG="--force"
  elif [ "$arg" == "workflows" ]; then
    MODE="workflows"
  elif [ "$arg" == "comfy" ]; then
    MODE="comfy"
  fi
done

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

# Function to log messages
log_message() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$BISYNC_LOG"
  echo "$1"
}

# Start sync process
log_message "Starting bidirectional sync for ComfyUI user settings (Mode: $MODE)"

# First, check if rclone can access the Dropbox
log_message "Testing Dropbox connectivity..."
if ! rclone lsd dbx: > /dev/null 2>&1; then
  log_message "ERROR: Cannot access Dropbox. Please check rclone configuration with 'rclone config'."
  exit 1
fi

# Set default timeout and transfer settings
TIMEOUT_FLAG="--timeout=30m"
TRANSFER_FLAGS="--transfers=4 --checkers=8"

# Sync ComfyUI settings and templates files
sync_comfy_settings() {
  log_message "Ensuring remote directory exists..."
  rclone mkdir "$DEST_DIR" >> "$BISYNC_LOG" 2>&1
  
  # Ensure local files exist (create empty if not)
  touch "$SOURCE_DIR/comfy.templates.json" 2>/dev/null
  touch "$SOURCE_DIR/comfy.settings.json" 2>/dev/null
  
  # Perform sync for each component separately for more robustness
  log_message "Syncing settings file..."
  rclone copy "$SOURCE_DIR/comfy.settings.json" "$DEST_DIR/" $TIMEOUT_FLAG --verbose >> "$BISYNC_LOG" 2>&1
  
  log_message "Syncing templates file..."
  rclone copy "$SOURCE_DIR/comfy.templates.json" "$DEST_DIR/" $TIMEOUT_FLAG --verbose >> "$BISYNC_LOG" 2>&1
  
  log_message "Checking for newer remote files to download..."
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
  
  log_message "ComfyUI settings sync completed successfully"
}

# Sync workflow files
sync_workflows() {
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

  # Ensure remote directories exist
  log_message "Ensuring workflow directories exist on both sides..."
  rclone mkdir "$DEST_DIR" >> "$BISYNC_LOG" 2>&1
  rclone mkdir "$DEST_DIR/workflows" >> "$BISYNC_LOG" 2>&1

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
    log_message "Workflows sync completed successfully"
    cat "$ERROR_LOG" >> "$BISYNC_LOG"
  else
    # If sync failed, try again with resync option
    log_message "Workflows sync failed, attempting with --resync option"
    rclone bisync "$SOURCE_DIR/workflows" "$DEST_DIR/workflows" --force --resync $TIMEOUT_FLAG $TRANSFER_FLAGS $EXCLUDE_FLAGS --verbose > "$ERROR_LOG" 2>&1
    
    if [ $? -eq 0 ]; then
      log_message "Workflows sync completed successfully with resync"
      cat "$ERROR_LOG" >> "$BISYNC_LOG"
    else
      # Try one more time with minimal operations for recovery
      log_message "Resync failed, attempting final recovery with minimal operations..."
      rclone bisync "$SOURCE_DIR/workflows" "$DEST_DIR/workflows" --force --resync $TIMEOUT_FLAG --max-delete 0 $EXCLUDE_FLAGS --verbose > "$ERROR_LOG" 2>&1
      
      if [ $? -eq 0 ]; then
        log_message "Minimal recovery sync completed successfully"
        cat "$ERROR_LOG" >> "$BISYNC_LOG"
      else
        log_message "ERROR: Workflows sync failed completely. Check details below:"
        cat "$ERROR_LOG" >> "$BISYNC_LOG"
        # Extract error message for log
        ERROR_MSG=$(grep -A 5 "ERROR" "$ERROR_LOG" 2>/dev/null | head -6)
        log_message "Error details: ${ERROR_MSG}"
      fi
    fi
  fi
}

# Run appropriate sync based on mode
if [ "$MODE" = "all" ] || [ "$MODE" = "comfy" ]; then
  sync_comfy_settings
fi

if [ "$MODE" = "all" ] || [ "$MODE" = "workflows" ]; then
  sync_workflows
fi

# Clean up
rm -f "$ERROR_LOG" 2>/dev/null

log_message "Bidirectional sync process finished (Mode: $MODE)"

exit 0
>>>>>>> origin/feature/command-cleanup
