#!/bin/bash

command="$1"
option="$2"

# Run both bisync and customsync scripts based on options
run_sync() {
  local force_flag=""
  if [ "$1" == "force" ]; then
    force_flag="force"
  fi
  
  # Default is to run both syncs
  local run_workflows=true
  local run_nodes=true
  
  # Check for specific options
  if [ "$2" == "--workflows" ]; then
    run_nodes=false
  elif [ "$2" == "--nodes" ]; then
    run_workflows=false
  fi
  # "--all" or no option runs both (default behavior)
  
  # Run the appropriate sync processes
  if $run_workflows; then
    /workspace/comfy-download/bisync_comfyui.sh $force_flag
  fi
  
  if $run_nodes; then
    /workspace/comfy-download/custom_sync.sh $force_flag
  fi
}

case "$command" in
  start)
    service cron start
    # Run backup immediately
    /workspace/comfy-download/backup_comfyui.sh force
    # Run node config checker
    /workspace/comfy-download/node_config_checker.sh apply
    # Run syncs immediately with the specified option or default to all
    run_sync force "$option"
    # Set up cron jobs
    (crontab -l 2>/dev/null | grep -q 'comfy-download/download_run.sh' || (crontab -l 2>/dev/null; echo '* * * * * /workspace/comfy-download/download_run.sh') | crontab -)
    (crontab -l 2>/dev/null | grep -q 'comfy-download/backup_comfyui.sh' || (crontab -l 2>/dev/null; echo '0 * * * * /workspace/comfy-download/backup_comfyui.sh') | crontab -)
    (crontab -l 2>/dev/null | grep -q 'comfy-download/bisync_comfyui.sh' || (crontab -l 2>/dev/null; echo '*/5 * * * * /workspace/comfy-download/bisync_comfyui.sh') | crontab -)
    (crontab -l 2>/dev/null | grep -q 'comfy-download/custom_sync.sh' || (crontab -l 2>/dev/null; echo '*/30 * * * * /workspace/comfy-download/custom_sync.sh') | crontab -)
    (crontab -l 2>/dev/null | grep -q 'comfy-download/node_config_checker.sh' || (crontab -l 2>/dev/null; echo '0 */6 * * * /workspace/comfy-download/node_config_checker.sh apply') | crontab -)
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

    # Add sync status information (combined workflows and custom nodes)
    echo -e "\nSync status:"
    
    # Workflow sync
    LAST_SYNC=$(grep "sync completed successfully" /workspace/ComfyUI/logs/bisync.log 2>/dev/null | tail -1)
    if [ -z "$LAST_SYNC" ]; then
      echo "No successful workflow syncs recorded"
    else
      echo "Workflows: $LAST_SYNC"
    fi
    
    # Custom node sync
    LAST_CUSTOM_SYNC=$(grep "Custom node data sync process finished" /workspace/ComfyUI/logs/custom_sync.log 2>/dev/null | tail -1)
    if [ -z "$LAST_CUSTOM_SYNC" ]; then
      echo "No custom node data syncs recorded"
    else
      echo "Custom nodes: $LAST_CUSTOM_SYNC"
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
    
  bisync|bi|sync)
    # Check the option passed and run sync accordingly
    run_sync force "$option"
    ;;
  
  # Keep these for backward compatibility, but they're now just aliases to sync with specific options
  customsync|cs)
    /workspace/comfy-download/custom_sync.sh force
    ;;
    
  checkconfig|cc)
    /workspace/comfy-download/node_config_checker.sh apply
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
    
    # Get sync information (combined section)
    echo -e "\nSync Status:"
    
    # Workflow sync
    LAST_SYNC=$(grep "sync completed successfully" /workspace/ComfyUI/logs/bisync.log 2>/dev/null | tail -1)
    if [ -z "$LAST_SYNC" ]; then
      echo "  No successful workflow syncs recorded"
    else
      echo "  Workflows: $LAST_SYNC"
    fi
    SYNC_COUNT=$(grep "sync completed successfully" /workspace/ComfyUI/logs/bisync.log 2>/dev/null | grep -c "$(date +%Y-%m-%d)")
    echo "  Workflow syncs today: $SYNC_COUNT"
    
    # Custom node sync
    LAST_CUSTOM_SYNC=$(grep "Custom node data sync process finished" /workspace/ComfyUI/logs/custom_sync.log 2>/dev/null | tail -1)
    if [ -z "$LAST_CUSTOM_SYNC" ]; then
      echo "  No custom node data syncs recorded"
    else
      echo "  Custom nodes: $LAST_CUSTOM_SYNC"
    fi
    CUSTOM_SYNC_COUNT=$(grep "Custom node data sync process finished" /workspace/ComfyUI/logs/custom_sync.log 2>/dev/null | grep -c "$(date +%Y-%m-%d)")
    echo "  Custom node syncs today: $CUSTOM_SYNC_COUNT"
    
    # Check storage usage
    WORKFLOW_SIZE=$(du -sh "/workspace/ComfyUI/user/default/workflows" 2>/dev/null | cut -f1)
    echo -e "\nStorage Usage:"
    echo "  Workflow directory size: ${WORKFLOW_SIZE:-"N/A"}"
    OUTPUT_SIZE=$(du -sh "/workspace/ComfyUI/output/$TODAY" 2>/dev/null | cut -f1)
    echo "  Today's output size: ${OUTPUT_SIZE:-"0B"}"
    
    # Check custom node data sizes
    STYLERHIGH_SIZE=$(du -sh "/workspace/comfy-data/milehighstyler" 2>/dev/null | cut -f1)
    PARAMS_SIZE=$(du -sh "/workspace/comfy-data/plushparameters" 2>/dev/null | cut -f1)
    PROMPTS_SIZE=$(du -sh "/workspace/comfy-data/plushprompts" 2>/dev/null | cut -f1)
    echo "  MileHighStyler data size: ${STYLERHIGH_SIZE:-"0B"}"
    echo "  Plush parameters size: ${PARAMS_SIZE:-"0B"}"
    echo "  Plush prompts size: ${PROMPTS_SIZE:-"0B"}"
    
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
    echo "dl start [--all|--workflows|--nodes] - Start the automatic download and sync system"
    echo "dl stop                           - Stop the automatic download and sync system"
    echo "dl status                         - Show current download and sync statistics"
    echo "dl report                         - Generate a comprehensive report of today's operations"
    echo "dl run                            - Run a download check manually once"
    echo "dl backup                         - Run a backup manually once"
    echo "dl sync [--all|--workflows|--nodes] - Run sync manually with options"
    echo "dl bisync                         - Alias for 'dl sync --workflows'"
    echo "dl bi                             - Alias for 'dl sync --workflows'"
    echo "dl customsync                     - Alias for 'dl sync --nodes'"
    echo "dl cs                             - Alias for 'dl sync --nodes'"
    echo "dl checkconfig                    - Check and fix custom node configurations"
    echo "dl cc                             - Alias for dl checkconfig"
    echo "dl reset                          - Clean up duplicate log entries"
    echo "dl help                           - Display this help message"
    ;;
esac