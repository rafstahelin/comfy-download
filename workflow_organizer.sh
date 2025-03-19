#!/bin/bash

# Script to help organize ComfyUI workflows, reducing main directory size
# It identifies rarely used workflows and moves them to an archive folder

WORKFLOW_DIR="/workspace/ComfyUI/user/default/workflows"
ARCHIVE_DIR="/workspace/ComfyUI/user/default/workflow-archive"
LOG_FILE="/workspace/ComfyUI/logs/workflow-organizer.log"

# ANSI color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Create necessary directories
mkdir -p "$WORKFLOW_DIR"
mkdir -p "$ARCHIVE_DIR"
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"

# Log function with timestamp and colors
log() {
  local level="INFO"
  local color=$BLUE
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  
  if [ "$1" == "SUCCESS" ]; then
    level="SUCCESS"
    color=$GREEN
    shift
  elif [ "$1" == "WARNING" ]; then
    level="WARNING"
    color=$YELLOW
    shift
  elif [ "$1" == "ERROR" ]; then
    level="ERROR"
    color=$RED
    shift
  fi
  
  echo -e "${color}[${timestamp}] [${level}] $1${NC}" | tee -a "$LOG_FILE"
}

# Function to get file size in MB
get_size_mb() {
  du -sm "$1" | cut -f1
}

# Clear screen and show header
clear
echo -e "${BOLD}${CYAN}╔══════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║  COMFYUI WORKFLOW ORGANIZER      ║${NC}"
echo -e "${BOLD}${CYAN}╚══════════════════════════════════╝${NC}"
echo -e "${BOLD}Date:${NC} $(date)\n"

# Get current sizes
WORKFLOW_SIZE=$(get_size_mb "$WORKFLOW_DIR")
ARCHIVE_SIZE=$(get_size_mb "$ARCHIVE_DIR")

log "Current workflow directory size: ${WORKFLOW_SIZE}MB"
log "Current archive directory size: ${ARCHIVE_SIZE}MB"

# Check if we need to reorganize
if [ "$WORKFLOW_SIZE" -le 30 ]; then
  log "SUCCESS" "Workflow directory size is already optimal (under 30MB). No action needed."
  exit 0
fi

log "Beginning workflow organization process..."

# Create folders for organization if they don't exist
mkdir -p "$WORKFLOW_DIR/active"
mkdir -p "$WORKFLOW_DIR/templates"
mkdir -p "$ARCHIVE_DIR/old_versions"
mkdir -p "$ARCHIVE_DIR/rarely_used"

# Count workflows
TOTAL_WORKFLOWS=$(find "$WORKFLOW_DIR" -maxdepth 1 -name "*.json" | wc -l)
log "Found $TOTAL_WORKFLOWS workflow files at root level"

# Calculate how many files to move to archive
# Target: Get to 30MB or less
TARGET_SIZE=30
MB_TO_REDUCE=$((WORKFLOW_SIZE - TARGET_SIZE))
if [ "$MB_TO_REDUCE" -le 0 ]; then
  MB_TO_REDUCE=0
fi

log "Need to reduce workflow directory by approximately ${MB_TO_REDUCE}MB"

# Step 1: Find and move workflows not modified in the last 30 days
log "Finding workflows not modified in the last 30 days..."
OLD_WORKFLOWS=$(find "$WORKFLOW_DIR" -maxdepth 1 -name "*.json" -type f -mtime +30)
OLD_COUNT=$(echo "$OLD_WORKFLOWS" | grep -c "^" || echo "0")

if [ "$OLD_COUNT" -gt 0 ]; then
  log "SUCCESS" "Found $OLD_COUNT workflows not modified in 30+ days"
  log "Moving these to archive/rarely_used directory..."
  
  echo "$OLD_WORKFLOWS" | while read -r file; do
    if [ -f "$file" ]; then
      filename=$(basename "$file")
      mv "$file" "$ARCHIVE_DIR/rarely_used/$filename"
      log "Moved: $filename to archive/rarely_used"
    fi
  done
else
  log "WARNING" "No old workflows found. Looking for other candidates..."
fi

# Step 2: Look for duplicates and versioned files
log "Looking for duplicate and versioned workflows..."
VERSION_COUNT=0

find "$WORKFLOW_DIR" -maxdepth 1 -name "*.json" | while read -r file; do
  filename=$(basename "$file")
  
  # Check if this appears to be a versioned file (contains v1, v2, etc.)
  if [[ "$filename" =~ v[0-9]+ ]] || [[ "$filename" =~ [._-]v[0-9]+ ]]; then
    # Get base name without version
    base_name=${filename%%[._-]v[0-9]*}
    base_name=${base_name%%v[0-9]*}
    
    # Look for higher versions
    higher_version_exists=false
    version_num=$(echo "$filename" | grep -o "v[0-9]\+" | tr -d 'v')
    
    find "$WORKFLOW_DIR" -maxdepth 1 -name "${base_name}*.json" | while read -r other_file; do
      other_filename=$(basename "$other_file")
      if [[ "$other_filename" =~ v[0-9]+ ]] || [[ "$other_filename" =~ [._-]v[0-9]+ ]]; then
        other_version=$(echo "$other_filename" | grep -o "v[0-9]\+" | tr -d 'v')
        if [ "$other_version" -gt "$version_num" ]; then
          higher_version_exists=true
          break
        fi
      fi
    done
    
    if [ "$higher_version_exists" = true ]; then
      # Move older version to archive
      mv "$file" "$ARCHIVE_DIR/old_versions/$filename"
      log "Moved older version: $filename to archive/old_versions"
      VERSION_COUNT=$((VERSION_COUNT + 1))
    fi
  fi
done

if [ "$VERSION_COUNT" -gt 0 ]; then
  log "SUCCESS" "Moved $VERSION_COUNT older versioned workflows to archive"
else
  log "INFO" "No older versions found to archive"
fi

# Step 3: Look for duplicate files with similar content
# This requires a bit more sophisticated approach
log "Looking for workflows with duplicate content..."
TEMP_DIR=$(mktemp -d)
HASH_FILE="$TEMP_DIR/workflow_hashes.txt"

# Create hash file for all workflows
find "$WORKFLOW_DIR" -maxdepth 1 -name "*.json" -type f | while read -r file; do
  filename=$(basename "$file")
  filesize=$(stat -c %s "$file")
  # Use first 1000 bytes as a quick hash to identify similar files
  hash=$(head -c 1000 "$file" | md5sum | awk '{print $1}')
  echo "$hash $filesize $filename" >> "$HASH_FILE"
done

# Sort by hash and size to group similar files
sort "$HASH_FILE" > "${HASH_FILE}.sorted"

# Find duplicates and move older ones
DUP_COUNT=0
prev_hash=""
prev_size=""
prev_file=""

cat "${HASH_FILE}.sorted" | while read -r hash size filename; do
  if [ "$hash" == "$prev_hash" ] && [ "$size" == "$prev_size" ]; then
    # Found potential duplicate, check modification time
    file1="$WORKFLOW_DIR/$prev_file"
    file2="$WORKFLOW_DIR/$filename"
    
    if [ -f "$file1" ] && [ -f "$file2" ]; then
      time1=$(stat -c %Y "$file1")
      time2=$(stat -c %Y "$file2")
      
      if [ "$time1" -lt "$time2" ]; then
        # file1 is older
        mv "$file1" "$ARCHIVE_DIR/rarely_used/$prev_file"
        log "Moved duplicate: $prev_file to archive/rarely_used (kept newer $filename)"
        DUP_COUNT=$((DUP_COUNT + 1))
      elif [ "$time1" -gt "$time2" ]; then
        # file2 is older
        mv "$file2" "$ARCHIVE_DIR/rarely_used/$filename"
        log "Moved duplicate: $filename to archive/rarely_used (kept newer $prev_file)"
        DUP_COUNT=$((DUP_COUNT + 1))
      fi
    fi
  fi
  
  prev_hash="$hash"
  prev_size="$size"
  prev_file="$filename"
done

if [ "$DUP_COUNT" -gt 0 ]; then
  log "SUCCESS" "Moved $DUP_COUNT duplicate workflows to archive"
else
  log "INFO" "No duplicates found to archive"
fi

# Clean up
rm -rf "$TEMP_DIR"

# Get updated sizes
NEW_WORKFLOW_SIZE=$(get_size_mb "$WORKFLOW_DIR")
NEW_ARCHIVE_SIZE=$(get_size_mb "$ARCHIVE_DIR")
REDUCTION=$((WORKFLOW_SIZE - NEW_WORKFLOW_SIZE))

log "SUCCESS" "Organization complete!"
log "New workflow directory size: ${NEW_WORKFLOW_SIZE}MB (reduced by ${REDUCTION}MB)"
log "New archive directory size: ${NEW_ARCHIVE_SIZE}MB"

if [ "$NEW_WORKFLOW_SIZE" -gt 30 ]; then
  log "WARNING" "Workflow directory is still larger than 30MB."
  echo ""
  echo -e "${BOLD}${YELLOW}Suggested Next Steps:${NC}"
  echo -e " ${CYAN}1.${NC} Move template workflows to ${BOLD}$WORKFLOW_DIR/templates/${NC}"
  echo -e " ${CYAN}2.${NC} Move your current active workflows to ${BOLD}$WORKFLOW_DIR/active/${NC}"
  echo -e " ${CYAN}3.${NC} Any remaining workflows at root level could be moved to ${BOLD}$ARCHIVE_DIR/rarely_used/${NC}"
  echo ""
  echo -e "You can manually move files with these commands:"
  echo -e " ${YELLOW}mv $WORKFLOW_DIR/*.json $WORKFLOW_DIR/active/${NC}"
  echo -e " ${YELLOW}mv $WORKFLOW_DIR/active/template*.json $WORKFLOW_DIR/templates/${NC}"
else
  log "SUCCESS" "Workflow directory is now optimized for efficient syncing!"
fi

echo ""
echo -e "${BOLD}${CYAN}Workflow organization completed at $(date +%H:%M:%S)${NC}"

exit 0