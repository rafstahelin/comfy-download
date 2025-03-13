#!/bin/bash

command="$1"

case "$command" in
  start)
    service cron start
    # Run backup immediately when starting the service
    /workspace/comfy-download/backup_comfyui.sh force
    
    # Set up cron job for image downloads (every minute)
    (crontab -l 2>/dev/null | grep -q 'comfy-download/download_run.sh' || (crontab -l 2>/dev/null; echo '* * * * * /workspace/comfy-download/download_run.sh') | crontab -)
    
    # Set up cron job for hourly backups
    (crontab -l 2>/dev/null | grep -q 'comfy-download/backup_comfyui.sh' || (crontab -l 2>/dev/null; echo '0 * * * * /workspace/comfy-download/backup_comfyui.sh') | crontab -)
    
    echo 'Image download and backup system started!'
    ;;
  
  stop)
    # Remove both download and backup cron jobs
    (crontab -l 2>/dev/null | grep -v 'comfy-download' | crontab -)
    echo 'Image download and backup system stopped!'
    ;;
  
  status)
    TODAY=$(date +%Y-%m-%d)
    echo "Today: $TODAY"
    echo "Log entries: $(cat /workspace/ComfyUI/logs/downloaded_$TODAY.log 2>/dev/null | wc -l)"
    echo "Unique files downloaded: $(sort /workspace/ComfyUI/logs/downloaded_$TODAY.log 2>/dev/null | uniq | wc -l)"
    echo "Files in output folder: $(find /workspace/ComfyUI/output/$TODAY -type f -name "*.png" 2>/dev/null | wc -l)"
    
    # Add backup status information
    echo -e "\nBackup status:"
    LAST_BACKUP=$(grep "Backup complete" /workspace/ComfyUI/logs/backup.log 2>/dev/null | tail -1)
    if [ -z "$LAST_BACKUP" ]; then
      echo "No backups recorded"
    else
      echo "$LAST_BACKUP"
    fi
    ;;
  
  run)
    /workspace/comfy-download/download_images.sh
    ;;
  
  backup)
    # Run a backup immediately
    /workspace/comfy-download/backup_comfyui.sh force
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
    echo "dl start   - Start the automatic download and backup system"
    echo "dl stop    - Stop the automatic download and backup system"
    echo "dl status  - Show current download and backup statistics"
    echo "dl run     - Run a download check manually once"
    echo "dl backup  - Run a backup manually once"
    echo "dl reset   - Clean up duplicate entries in the log file"
    echo "dl help    - Display this help message"
    ;;
esac