#!/bin/bash

command="$1"
shift 1  # Remove the command from the arguments list
options="$@"  # Capture all remaining arguments

# Parse options from the remaining arguments
parse_options() {
  local run_workflows=true
  local run_nodes=true
  local run_comfy=true
  
  for opt in $@; do
    case "$opt" in
      --workflows)
        run_nodes=false
        run_comfy=false
        ;;
      --nodes)
        run_workflows=false
        run_comfy=false
        ;;
      --comfy)
        run_workflows=false
        run_nodes=false
        ;;
      # --all is redundant but kept for backward compatibility
      --all)
        run_workflows=true
        run_nodes=true
        run_comfy=true
        ;;
    esac
  done
  
  echo "$run_workflows $run_nodes $run_comfy"
}

# Run sync scripts based on options
run_sync() {
  local force_flag="force"  # Always force when manual
  local parsed_options=$(parse_options $@)
  local run_workflows=$(echo $parsed_options | cut -d' ' -f1)
  local run_nodes=$(echo $parsed_options | cut -d' ' -f2)
  local run_comfy=$(echo $parsed_options | cut -d' ' -f3)
  
  if [ "$run_workflows" = "true" ]; then
    echo "Running workflow synchronization..."
    /workspace/comfy-download/bisync_comfyui.sh $force_flag workflows
  fi
  
  if [ "$run_nodes" = "true" ]; then
    echo "Running custom node data synchronization..."
    /workspace/comfy-download/custom_sync.sh $force_flag
  fi
  
  if [ "$run_comfy" = "true" ]; then
    echo "Running ComfyUI settings synchronization..."
    /workspace/comfy-download/bisync_comfyui.sh $force_flag comfy
  fi
}

# Function to show deprecated command warnings
show_deprecated_warning() {
  local old_cmd="$1"
  local new_cmd="$2"
  echo "Warning: '$old_cmd' is deprecated and will be removed in a future update."
  echo "Please use '$new_cmd' instead."
  echo ""
}

# Display time in both UTC and local (Panama) time
show_time() {
  local utc_time=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
  local panama_time=$(TZ="America/Panama" date +"%Y-%m-%d %H:%M:%S Panama")
  echo "Current time: $utc_time / $panama_time"
}

# Start cron jobs based on options
start_cron_jobs() {
  local parsed_options=$(parse_options $@)
  local run_workflows=$(echo $parsed_options | cut -d' ' -f1)
  local run_nodes=$(echo $parsed_options | cut -d' ' -f2)
  local run_comfy=$(echo $parsed_options | cut -d' ' -f3)
  
  service cron start
  
  # Always start these core services
  (crontab -l 2>/dev/null | grep -q 'comfy-download/download_run.sh' || (crontab -l 2>/dev/null; echo '* * * * * /workspace/comfy-download/download_run.sh') | crontab -)
  (crontab -l 2>/dev/null | grep -q 'comfy-download/backup_comfyui.sh' || (crontab -l 2>/dev/null; echo '*/30 * * * * /workspace/comfy-download/backup_comfyui.sh') | crontab -)
  (crontab -l 2>/dev/null | grep -q 'comfy-download/node_config_checker.sh' || (crontab -l 2>/dev/null; echo '0 */6 * * * /workspace/comfy-download/node_config_checker.sh apply') | crontab -)
  
  # Start workflow sync if specified
  if [ "$run_workflows" = "true" ]; then
    (crontab -l 2>/dev/null | grep -q 'bisync_comfyui.sh.*workflows' || (crontab -l 2>/dev/null; echo '*/5 * * * * /workspace/comfy-download/bisync_comfyui.sh workflows') | crontab -)
    echo "Workflow synchronization service started"
  fi
  
  # Start custom node sync if specified
  if [ "$run_nodes" = "true" ]; then
    (crontab -l 2>/dev/null | grep -q 'comfy-download/custom_sync.sh' || (crontab -l 2>/dev/null; echo '*/30 * * * * /workspace/comfy-download/custom_sync.sh') | crontab -)
    echo "Custom node synchronization service started"
  fi
  
  # Start comfy settings sync if specified
  if [ "$run_comfy" = "true" ]; then
    (crontab -l 2>/dev/null | grep -q 'bisync_comfyui.sh.*comfy' || (crontab -l 2>/dev/null; echo '*/10 * * * * /workspace/comfy-download/bisync_comfyui.sh comfy') | crontab -)
    echo "ComfyUI settings synchronization service started"
  fi
}

case "$command" in
  start)
    # Show current time
    show_time
    
    # Run immediate operations
    echo "Starting services..."
    /workspace/comfy-download/backup_comfyui.sh force
    /workspace/comfy-download/node_config_checker.sh apply
    run_sync $options
    
    # Set up cron jobs
    start_cron_jobs $options
    echo 'All services started successfully!'
    ;;
  
  stop)
    (crontab -l 2>/dev/null | grep -v 'comfy-download' | crontab -)
    echo 'All services stopped.'
    ;;
  
  status)
    # Show current time
    show_time
    
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

    # Add sync status information (all types)
    echo -e "\nSync status:"
    
    # Workflow sync
    LAST_SYNC=$(grep "sync completed successfully" /workspace/ComfyUI/logs/bisync.log 2>/dev/null | grep "workflows" | tail -1)
    if [ -z "$LAST_SYNC" ]; then
      echo "No successful workflow syncs recorded"
    else
      echo "Workflows: $LAST_SYNC"
    fi
    
    # ComfyUI settings sync
    LAST_COMFY_SYNC=$(grep "sync completed successfully" /workspace/ComfyUI/logs/bisync.log 2>/dev/null | grep "comfy" | tail -1)
    if [ -z "$LAST_COMFY_SYNC" ]; then
      echo "No successful ComfyUI settings syncs recorded"
    else
      echo "ComfyUI settings: $LAST_COMFY_SYNC"
    fi
    
    # Custom node sync
    LAST_CUSTOM_SYNC=$(grep "Custom node data sync process finished" /workspace/ComfyUI/logs/custom_sync.log 2>/dev/null | tail -1)
    if [ -z "$LAST_CUSTOM_SYNC" ]; then
      echo "No custom node data syncs recorded"
    else
      echo "Custom nodes: $LAST_CUSTOM_SYNC"
    fi

    # List node directories being synced
    echo -e "\nCustom node directories being synced:"
    if [ -d "/workspace/comfy-data/milehighstyler" ]; then
      echo "- milehighstyler: $(du -sh "/workspace/comfy-data/milehighstyler" 2>/dev/null | cut -f1)"
    fi
    if [ -d "/workspace/comfy-data/plushparameters" ]; then
      echo "- plushparameters: $(du -sh "/workspace/comfy-data/plushparameters" 2>/dev/null | cut -f1)"
    fi
    if [ -d "/workspace/comfy-data/plushprompts" ]; then
      echo "- plushprompts: $(du -sh "/workspace/comfy-data/plushprompts" 2>/dev/null | cut -f1)"
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
    echo "Running manual image download..."
    /workspace/comfy-download/download_images.sh
    ;;
    
  backup)
    echo "Running manual backup..."
    /workspace/comfy-download/backup_comfyui.sh force
    ;;
    
  sync)
    run_sync $options
    ;;
  
  # Handle deprecated commands with warnings
  bisync|bi)
    show_deprecated_warning "dl $command" "dl sync --workflows"
    run_sync --workflows
    ;;
    
  customsync|cs)
    show_deprecated_warning "dl $command" "dl sync --nodes"
    run_sync --nodes
    ;;
    
  checkconfig|cc)
    if [ "$command" = "cc" ]; then
      # cc is the only alias we'll keep, but we'll still show a gentle reminder
      echo "Note: 'cc' is an alias for 'checkconfig'\n"
    fi
    echo "Checking and fixing node configurations..."
    /workspace/comfy-download/node_config_checker.sh apply
    ;;
    
  report)
    # Show current time
    show_time
    
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
    
    # Get sync information (all types)
    echo -e "\nSync Status:"
    
    # Workflow sync
    LAST_SYNC=$(grep "sync completed successfully" /workspace/ComfyUI/logs/bisync.log 2>/dev/null | grep "workflows" | tail -1)
    if [ -z "$LAST_SYNC" ]; then
      echo "  No successful workflow syncs recorded"
    else
      echo "  Workflows: $LAST_SYNC"
    fi
    SYNC_COUNT=$(grep "sync completed successfully" /workspace/ComfyUI/logs/bisync.log 2>/dev/null | grep "workflows" | grep -c "$(date +%Y-%m-%d)")
    echo "  Workflow syncs today: $SYNC_COUNT"
    
    # ComfyUI settings sync
    LAST_COMFY_SYNC=$(grep "sync completed successfully" /workspace/ComfyUI/logs/bisync.log 2>/dev/null | grep "comfy" | tail -1)
    if [ -z "$LAST_COMFY_SYNC" ]; then
      echo "  No successful ComfyUI settings syncs recorded"
    else
      echo "  ComfyUI settings: $LAST_COMFY_SYNC"
    fi
    COMFY_SYNC_COUNT=$(grep "sync completed successfully" /workspace/ComfyUI/logs/bisync.log 2>/dev/null | grep "comfy" | grep -c "$(date +%Y-%m-%d)")
    echo "  ComfyUI settings syncs today: $COMFY_SYNC_COUNT"
    
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
    echo "ComfyUI Download Manager - Command Reference"
    echo "===========================================\n"
    
    echo "CORE COMMANDS:"
    echo "  dl start                   - Start all automated services"
    echo "    --workflows              - Only start workflow sync services"
    echo "    --nodes                  - Only start custom node sync services"
    echo "    --comfy                  - Only start ComfyUI settings sync services"
    echo "  dl stop                    - Stop all automated services"
    echo "  dl status                  - Show current system status"
    echo "  dl help                    - Display this help message\n"
    
    echo "MANUAL OPERATIONS:"
    echo "  dl run                     - Process new images once"
    echo "  dl backup                  - Run backup manually once"
    echo "  dl sync                    - Run complete sync manually"
    echo "    --workflows              - Sync only workflows"
    echo "    --nodes                  - Sync only custom nodes"
    echo "    --comfy                  - Sync only ComfyUI settings"
    echo "  dl checkconfig (cc)        - Check and fix node configurations\n"
    
    echo "UTILITIES:"
    echo "  dl report                  - Generate comprehensive system report"
    echo "  dl reset                   - Clean up duplicate log entries"
    
    # Show custom node details
    echo "\nCUSTOM NODE DIRECTORIES:"
    if [ -d "/workspace/comfy-data/milehighstyler" ]; then
      size_mhs=$(du -sh "/workspace/comfy-data/milehighstyler" 2>/dev/null | cut -f1)
      echo "  - milehighstyler (${size_mhs:-"N/A"})"
    else
      echo "  - milehighstyler (not found)"
    fi
    if [ -d "/workspace/comfy-data/plushparameters" ]; then
      size_pp=$(du -sh "/workspace/comfy-data/plushparameters" 2>/dev/null | cut -f1)
      echo "  - plushparameters (${size_pp:-"N/A"})"
    else
      echo "  - plushparameters (not found)"
    fi
    if [ -d "/workspace/comfy-data/plushprompts" ]; then
      size_pr=$(du -sh "/workspace/comfy-data/plushprompts" 2>/dev/null | cut -f1)
      echo "  - plushprompts (${size_pr:-"N/A"})"
    else
      echo "  - plushprompts (not found)"
    fi
    
    # Show deprecated commands notice
    echo "\nDEPRECATED COMMANDS:"
    echo "  The following commands will be removed in a future update:"
    echo "  dl bisync, dl bi           → use 'dl sync --workflows' instead"
    echo "  dl customsync, dl cs       → use 'dl sync --nodes' instead"
    ;;
esac