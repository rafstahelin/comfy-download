#!/bin/bash

# Script to validate and fix custom node configurations
# Usage: node_config_checker.sh [check|apply]
# If "check" parameter is provided, script will only report issues without fixing them
# If "apply" parameter is provided or no parameter, script will fix issues

# Logs directory
LOGS_DIR="/workspace/ComfyUI/logs"
CONFIG_LOG="$LOGS_DIR/node_config.log"

# Create necessary directories
mkdir -p "$LOGS_DIR"

# Define paths
PLUSH_CONFIG="/workspace/ComfyUI/custom_nodes/Plush-for-ComfyUI/user/text_file_dirs.json"
PLUSH_DIR="/workspace/ComfyUI/custom_nodes/Plush-for-ComfyUI"
EASYUSE_STYLES="/workspace/ComfyUI/custom_nodes/ComfyUI-Easy-Use/styles"
STYLES_TARGET="/workspace/comfy-data/milehighstyler"

# Expected Plush configuration
EXPECTED_CONFIG='{
	"parameter files": "/workspace/comfy-data/plushparameters/**/*param*.txt",
	"image meta-data files": "/workspace/comfy-data/plushprompts/**/*ew*.txt"
}'

# Check if we should only check without applying fixes
CHECK_ONLY=false
if [ "$1" == "check" ]; then
  CHECK_ONLY=true
fi

# Function to log messages
log_message() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$CONFIG_LOG"
  echo "$1"
}

# Start configuration check
log_message "Starting custom node configuration check"

# Function to check and update Plush config
check_plush_config() {
  # Check if Plush directory exists
  if [ ! -d "$PLUSH_DIR" ]; then
    log_message "Plush directory not found at $PLUSH_DIR"
    return 0
  fi
  
  # Create directory if needed
  mkdir -p "$(dirname "$PLUSH_CONFIG")"
  
  # Check if config exists and has correct content
  if [ ! -f "$PLUSH_CONFIG" ]; then
    log_message "Plush configuration file not found"
    if $CHECK_ONLY; then
      log_message "[CHECK] Would create new Plush configuration file"
    else
      log_message "Creating new Plush configuration file"
      echo "$EXPECTED_CONFIG" > "$PLUSH_CONFIG"
      log_message "Plush configuration file created"
    fi
  else
    # Check if the configuration is correct
    if ! grep -q "comfy-data/plushparameters" "$PLUSH_CONFIG" || ! grep -q "comfy-data/plushprompts" "$PLUSH_CONFIG"; then
      log_message "Plush configuration needs updating"
      if $CHECK_ONLY; then
        log_message "[CHECK] Would update Plush configuration file"
      else
        log_message "Updating Plush configuration file"
        cp "$PLUSH_CONFIG" "${PLUSH_CONFIG}.bak"
        echo "$EXPECTED_CONFIG" > "$PLUSH_CONFIG"
        log_message "Plush configuration updated (backup at ${PLUSH_CONFIG}.bak)"
      fi
    else
      log_message "Plush configuration is already correct"
    fi
  fi
  
  # Verify .gitattributes to prevent overwriting our configuration
  GITATTRIBUTES="$PLUSH_DIR/.gitattributes"
  if [ ! -f "$GITATTRIBUTES" ] || ! grep -q "user/text_file_dirs.json merge=ours" "$GITATTRIBUTES"; then
    log_message "Plush .gitattributes file needs to be updated for text_file_dirs.json"
    if $CHECK_ONLY; then
      log_message "[CHECK] Would update .gitattributes file"
    else
      if [ -f "$GITATTRIBUTES" ]; then
        echo "user/text_file_dirs.json merge=ours" >> "$GITATTRIBUTES"
      else
        echo "user/text_file_dirs.json merge=ours" > "$GITATTRIBUTES"
      fi
      log_message "Added gitattributes protection for text_file_dirs.json"
    fi
  else
    log_message "Plush .gitattributes file already has merge protection"
  fi
}

# Function to set up EasyUse symlink
setup_easyuse_symlink() {
  # Check if EasyUse directory exists
  if [ ! -d "/workspace/ComfyUI/custom_nodes/ComfyUI-Easy-Use" ]; then
    log_message "ComfyUI-Easy-Use directory not found"
    return 0
  fi
  
  # Create target directory if it doesn't exist
  mkdir -p "$STYLES_TARGET"
  
  if [ -L "$EASYUSE_STYLES" ]; then
    # Link exists, check if it points to the correct location
    LINK_TARGET=$(readlink "$EASYUSE_STYLES")
    if [ "$LINK_TARGET" != "$STYLES_TARGET" ]; then
      log_message "EasyUse styles symlink points to wrong location: $LINK_TARGET"
      if $CHECK_ONLY; then
        log_message "[CHECK] Would update EasyUse styles symlink"
      else
        log_message "Updating EasyUse styles symlink"
        rm "$EASYUSE_STYLES"
        ln -s "$STYLES_TARGET" "$EASYUSE_STYLES"
        log_message "EasyUse styles symlink updated"
      fi
    else
      log_message "EasyUse styles symlink is correct"
    fi
  elif [ -d "$EASYUSE_STYLES" ]; then
    # Directory exists but is not a symlink
    log_message "EasyUse styles is a directory, not a symlink"
    if $CHECK_ONLY; then
      log_message "[CHECK] Would convert EasyUse styles directory to symlink"
    else
      log_message "Converting EasyUse styles to symlink"
      # Backup existing files
      if [ "$(ls -A "$EASYUSE_STYLES" 2>/dev/null)" ]; then
        log_message "Backing up existing styles to $STYLES_TARGET"
        cp -r "$EASYUSE_STYLES/"* "$STYLES_TARGET/" 2>/dev/null
      fi
      # Create symlink
      mv "$EASYUSE_STYLES" "${EASYUSE_STYLES}_backup"
      ln -s "$STYLES_TARGET" "$EASYUSE_STYLES"
      log_message "EasyUse styles converted to symlink (backup at ${EASYUSE_STYLES}_backup)"
    fi
  else
    # Neither link nor directory exists
    log_message "EasyUse styles path doesn't exist"
    if $CHECK_ONLY; then
      log_message "[CHECK] Would create EasyUse styles symlink"
    else
      log_message "Creating EasyUse styles symlink"
      mkdir -p "$(dirname "$EASYUSE_STYLES")"
      ln -s "$STYLES_TARGET" "$EASYUSE_STYLES"
      log_message "EasyUse styles symlink created"
    fi
  fi
}

# Run configuration checks
check_plush_config
setup_easyuse_symlink

log_message "Custom node configuration check completed"

exit 0