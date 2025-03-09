#!/bin/bash

command="$1"

case "$command" in
  start)
    service cron start
    (crontab -l 2>/dev/null | grep -q 'comfy-download' || (crontab -l 2>/dev/null; echo '* * * * * /workspace/comfy-download/download_run.sh') | crontab -)
    echo 'Image download system started!'
    ;;
  
  stop)
    (crontab -l 2>/dev/null | grep -v 'comfy-download' | crontab -)
    echo 'Image download system stopped!'
    ;;
  
  status)
    TODAY=$(date +%Y-%m-%d)
    echo "Today: $TODAY"
    echo "Log entries: $(cat /workspace/ComfyUI/logs/downloaded_$TODAY.log 2>/dev/null | wc -l)"
    echo "Unique files downloaded: $(sort /workspace/ComfyUI/logs/downloaded_$TODAY.log 2>/dev/null | uniq | wc -l)"
    echo "Files in output folder: $(find /workspace/ComfyUI/output/$TODAY -type f -name "*.png" 2>/dev/null | wc -l)"
    ;;
  
  run)
    /workspace/comfy-download/download_images.sh
    ;;
  
  reset)
    TODAY=$(date +%Y-%m-%d)
    echo "Backing up old log to downloaded_$TODAY.bak"
    cp /workspace/ComfyUI/logs/downloaded_$TODAY.log /workspace/ComfyUI/logs/downloaded_$TODAY.log.bak 2>/dev/null || true
    echo "Cleaning log file"
    cat /workspace/ComfyUI/logs/downloaded_$TODAY.log.bak 2>/dev/null | sort | uniq > /workspace/ComfyUI/logs/downloaded_$TODAY.log 2>/dev/null || true
    echo "Done."
    ;;
  
  help|*)
    echo "Download Manager Command Reference:"
    echo "----------------------------------"
    echo "dl start   - Start the automatic download system"
    echo "dl stop    - Stop the automatic download system"
    echo "dl status  - Show current download statistics"
    echo "dl run     - Run a download check manually once"
    echo "dl reset   - Clean up duplicate entries in the log file"
    echo "dl help    - Display this help message"
    ;;
esac
