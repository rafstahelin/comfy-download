#!/bin/bash

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