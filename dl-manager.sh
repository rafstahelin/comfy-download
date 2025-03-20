#!/bin/bash

command="$1"

case "$command" in
  start)
    service cron start
    # Run backup immediately
    /workspace/comfy-download/backup_comfyui.sh force
    # Run bisync immediately to sync with latest settings from Dropbox
    /workspace/comfy-download/bisync_comfyui.sh force
    # Set up cron jobs
    (crontab -l 2>/dev/null | grep -q 'comfy-download/download_run.sh' || (crontab -l 2>/dev/null; echo '* * * * * /workspace/comfy-download/download_run.sh') | crontab -)
    (crontab -l 2>/dev/null | grep -q 'comfy-download/backup_comfyui.sh' || (crontab -l 2>/dev/null; echo '0 * * * * /workspace/comfy-download/backup_comfyui.sh') | crontab -)
    (crontab -l 2>/dev/null | grep -q 'comfy-download/bisync_comfyui.sh' || (crontab -l 2>/dev/null; echo '*/5 * * * * /workspace/comfy-download/bisync_comfyui.sh') | crontab -)
    echo 'Image download, backup and bidirectional sync system started!'
    ;;
  
  stop)
    (crontab -l 2>/dev/null | grep -v 'comfy-download' | crontab -)
    echo 'Image download, backup and bidirectional sync system stopped!'
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

    # Add bisync status information
    echo -e "\nBidirectional sync status:"
    LAST_SYNC=$(grep "sync completed successfully" /workspace/ComfyUI/logs/bisync.log 2>/dev/null | tail -1)
    if [ -z "$LAST_SYNC" ]; then
      echo "No successful syncs recorded"
    else
      echo "$LAST_SYNC"
    fi

    # Check workflow size
    if [ -d "/workspace/ComfyUI/user/default/workflows" ]; then
      WORKFLOW_SIZE=$(du -sh "/workspace/ComfyUI/user/default/workflows" | cut -f1)
      echo -e "\nWorkflow directory size: $WORKFLOW_SIZE"
      if [[ "$WORKFLOW_SIZE" == *"G"* ]] || [[ "${WORKFLOW_SIZE%M}" -gt 50 ]]; then
        echo "WARNING: Large workflow directory may slow down sync operations"
        echo "Consider archiving unused workflows elsewhere"
      fi
    fi
    ;;
  
  run)
    /workspace/comfy-download/download_images.sh
    ;;
    
  backup)
    /workspace/comfy-download/backup_comfyui.sh force
    ;;
    
  bisync|bi)
    /workspace/comfy-download/bisync_comfyui.sh force
    ;;
    
  report)
    TODAY=$(date +%Y-%m-%d)
    echo "========== Download System Report: $TODAY =========="
    echo "Download Statistics:"
    echo "  Log entries: $(cat /workspace/ComfyUI/logs/downloaded_$TODAY.log 2>/dev/null | wc -l)"
    echo "  Unique files downloaded: $(sort /workspace/ComfyUI/logs/downloaded_$TODAY.log 2>/dev/null | uniq | wc -l)"
    echo "  Files in output folder: $(find /workspace/ComfyUI/output/$TODAY -type f -name "*.png" 2>/dev/null | wc -l)"
    
    # Get backup information
    echo -e "\nLatest Backup:"
    LAST_BACKUP=$(grep "Backup complete" /workspace/ComfyUI/logs/backup.log 2>/dev/null | tail -1)
    if [ -z "$LAST_BACKUP" ]; then
      echo "  No backups recorded"
    else
      echo "  $LAST_BACKUP"
    fi
    BACKUP_COUNT=$(grep "Backup complete" /workspace/ComfyUI/logs/backup.log 2>/dev/null | grep -c "$(date +%Y-%m-%d)")
    echo "  Backups today: $BACKUP_COUNT"
    
    # Get sync information
    echo -e "\nBidirectional Sync Status:"
    LAST_SYNC=$(grep "sync completed successfully" /workspace/ComfyUI/logs/bisync.log 2>/dev/null | tail -1)
    if [ -z "$LAST_SYNC" ]; then
      echo "  No successful syncs recorded"
    else
      echo "  $LAST_SYNC"
    fi
    SYNC_COUNT=$(grep "sync completed successfully" /workspace/ComfyUI/logs/bisync.log 2>/dev/null | grep -c "$(date +%Y-%m-%d)")
    echo "  Successful syncs today: $SYNC_COUNT"
    
    # Check storage usage
    WORKFLOW_SIZE=$(du -sh "/workspace/ComfyUI/user/default/workflows" 2>/dev/null | cut -f1)
    echo -e "\nStorage Usage:"
    echo "  Workflow directory size: ${WORKFLOW_SIZE:-"N/A"}"
    OUTPUT_SIZE=$(du -sh "/workspace/ComfyUI/output/$TODAY" 2>/dev/null | cut -f1)
    echo "  Today's output size: ${OUTPUT_SIZE:-"0B"}"
    
    echo "=================================================="
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
    echo "Command Reference:"
    echo "------------------"
    echo "dl start   - Start the automatic download, backup and bidirectional sync system"
    echo "dl stop    - Stop the automatic download, backup and bidirectional sync system"
    echo "dl status  - Show current download, backup and sync statistics"
    echo "dl report  - Generate a comprehensive report of today's operations"
    echo "dl run     - Run a download check manually once"
    echo "dl backup  - Run a backup manually once"
    echo "dl bisync  - Run a bidirectional sync manually once"
    echo "dl bi      - Alias for dl bisync"
    echo "dl reset   - Clean up duplicate log entries"
    echo "dl help    - Display this help message"
    ;;
esac