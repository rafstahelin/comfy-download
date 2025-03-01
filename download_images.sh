#!/bin/bash

# Set variables
TODAY=$(date +%Y-%m-%d)
SOURCE_DIR="/workspace/ComfyUI/output/$TODAY"
DEST_DIR="dbx:/studio/ai/output/output-eagle.library/output-eagle"
LOG_DIR="/workspace/ComfyUI/logs"
LOG_FILE="$LOG_DIR/downloaded_$TODAY.log"

# Create log directory and file if they don't exist
mkdir -p "$LOG_DIR"
touch "$LOG_FILE"

# Check if source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo "$(date +"%Y-%m-%d %H:%M:%S") - Source directory $SOURCE_DIR does not exist. Exiting."
    exit 1
fi

# Find all PNG files in the source directory
find "$SOURCE_DIR" -type f -name "*.png" | while IFS= read -r file; do
    # Get just the filename without path
    filename=$(basename "$file")
    
    # Use grep with word boundaries to avoid partial matches
    if ! grep -q "^$filename$" "$LOG_FILE"; then
        echo "$(date +"%Y-%m-%d %H:%M:%S") - Downloading: $filename"
        
        # Use rclone to copy the specific file
        rclone copy --checksum "$file" "$DEST_DIR" -v
        
        # If successful, add to log only if not already present (additional check)
        if [ $? -eq 0 ] && ! grep -q "^$filename$" "$LOG_FILE"; then
            echo "$filename" >> "$LOG_FILE"
            echo "$(date +"%Y-%m-%d %H:%M:%S") - Successfully downloaded: $filename"
        else
            echo "$(date +"%Y-%m-%d %H:%M:%S") - Failed to download or already in log: $filename"
        fi
    else
        echo "$(date +"%Y-%m-%d %H:%M:%S") - Skipping already downloaded: $filename"
    fi
done

echo "$(date +"%Y-%m-%d %H:%M:%S") - Download check completed"