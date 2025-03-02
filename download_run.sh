#!/bin/bash

# This script runs in a loop for 1 minute, executing our download script every 10 seconds

# Set variables
SCRIPT_PATH="/workspace/comfy-download/download_images.sh"
LOG_DIR="/workspace/ComfyUI/logs"
CRON_LOG="$LOG_DIR/cron.log"

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Ensure our main script is executable
chmod +x "$SCRIPT_PATH"

# Run the script 6 times (once every 10 seconds for a minute)
for i in {1..6}; do
    echo "$(date +"%Y-%m-%d %H:%M:%S") - Running download check #$i of 6" >> "$CRON_LOG" 2>&1
    "$SCRIPT_PATH" >> "$CRON_LOG" 2>&1
    
    # Don't sleep after the last iteration
    if [ $i -lt 6 ]; then
        sleep 10
    fi
done