#!/bin/bash

# Color definitions for better visual output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Get the current date and time
get_formatted_time() {
  date "+%Y-%m-%d %H:%M:%S"
}

# Print section header
print_section() {
  echo -e "\n${BLUE}${BOLD}$1${NC}\n"
}

# Print success message
print_success() {
  echo -e "${GREEN}✓ $1${NC}"
}

# Print status message
print_status() {
  echo -e "${CYAN}→ $1${NC}"
}

# Print warning message
print_warning() {
  echo -e "${YELLOW}! $1${NC}"
}

# Print error message
print_error() {
  echo -e "${RED}✗ $1${NC}"
}

# Print info message
print_info() {
  echo -e "${GRAY}  $1${NC}"
}

# Function to display file sync status with appropriate icon
print_file_sync_status() {
    local file="$1"
    local status="$2"
    local local_time="$3"
    local remote_time="$4"
    
    case "$status" in
        UPLOAD_NEWER)
            echo -e "  ${YELLOW}↑${NC} $file ${GRAY}(Local is newer - uploading to Dropbox)${NC}"
            echo -e "    ${GRAY}Local: $local_time${NC}"
            echo -e "    ${GRAY}Remote: $remote_time${NC}"
            ;;
        DOWNLOAD_NEWER)
            echo -e "  ${GREEN}↓${NC} $file ${GRAY}(Remote is newer - downloading to local)${NC}"
            echo -e "    ${GRAY}Local: $local_time${NC}"
            echo -e "    ${GRAY}Remote: $remote_time${NC}"
            ;;
        UPLOAD_NEW)
            echo -e "  ${YELLOW}↑${NC} $file ${GRAY}(New file - uploading to Dropbox)${NC}"
            echo -e "    ${GRAY}Local: $local_time${NC}"
            ;;
        DOWNLOAD_NEW)
            echo -e "  ${GREEN}↓${NC} $file ${GRAY}(New file - downloading from Dropbox)${NC}"
            echo -e "    ${GRAY}Remote: $remote_time${NC}"
            ;;
        IN_SYNC)
            echo -e "  ${BLUE}✓${NC} $file ${GRAY}(Already in sync)${NC}"
            echo -e "    ${GRAY}Last modified: $local_time${NC}"
            ;;
        MISSING_BOTH)
            echo -e "  ${RED}!${NC} $file ${GRAY}(Missing from both local and remote)${NC}"
            ;;
        UNKNOWN)
            echo -e "  ${GRAY}?${NC} $file ${GRAY}(Status unknown)${NC}"
            ;;
    esac
}

command="$1"
shift 1  # Remove the command from the arguments list
options="$@"  # Capture all remaining arguments

# Tracking variables to avoid duplicate operations
sync_workflows_done=false
sync_nodes_done=false
sync_comfy_done=false

# Parse options from the remaining arguments
parse_options() {
  local run_workflows=true
  local run_nodes=true
  local run_comfy=true
  
  for opt in $@; do
    case "$opt" in
      --workflows|wf)
        run_nodes=false
        run_comfy=false
        ;;
      --nodes|nd)
        run_workflows=false
        run_comfy=false
        ;;
<<<<<<< HEAD
      --comfy|cf)
=======
      --comfy)
>>>>>>> origin/feature/command-cleanup
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
  
<<<<<<< HEAD
  if [ "$run_workflows" = "true" ] && [ "$sync_workflows_done" = "false" ]; then
    print_section "Workflow Synchronization"
    print_status "Running workflow sync..."
    output=$(/workspace/comfy-download/bisync_comfyui.sh $force_flag --workflows 2>&1)
    if echo "$output" | grep -q "completed successfully"; then
      print_success "Workflow sync completed"
    else
      print_error "Workflow sync encountered an issue"
      echo -e "${GRAY}$(echo "$output" | tail -5)${NC}"
    fi
    sync_workflows_done=true
=======
  if [ "$run_workflows" = "true" ]; then
    echo "Running workflow synchronization..."
    /workspace/comfy-download/bisync_comfyui.sh $force_flag workflows
>>>>>>> origin/feature/command-cleanup
  fi
  
  if [ "$run_nodes" = "true" ] && [ "$sync_nodes_done" = "false" ]; then
    print_section "Custom Node Data Synchronization"
    print_status "Running custom node data sync..."
    output=$(/workspace/comfy-download/custom_sync.sh $force_flag 2>&1)
    if echo "$output" | grep -q "Custom node data sync process finished"; then
      print_success "Custom node data sync completed"
    else
      print_error "Custom node sync encountered an issue"
      echo -e "${GRAY}$(echo "$output" | tail -5)${NC}"
    fi
    sync_nodes_done=true
  fi
  
  if [ "$run_comfy" = "true" ] && [ "$sync_comfy_done" = "false" ]; then
    print_section "ComfyUI Settings Synchronization"
    print_status "Running ComfyUI settings sync..."
    output=$(/workspace/comfy-download/bisync_comfyui.sh $force_flag --comfy --verbose 2>&1)
    
    print_status "Sync details:"
    
    # Parse file information for comfy.settings.json
    if echo "$output" | grep -q "comfy.settings.json:"; then
        local file="comfy.settings.json"
        local status=$(echo "$output" | grep -A 5 "comfy.settings.json:" | grep "STATUS:" | awk '{print $2}')
        local local_time=$(echo "$output" | grep -A 5 "comfy.settings.json:" | grep "Local:" | head -1 | sed 's/Local: //')
        local remote_time=$(echo "$output" | grep -A 5 "comfy.settings.json:" | grep "Remote:" | head -1 | sed 's/Remote: //')
        
        print_file_sync_status "$file" "$status" "$local_time" "$remote_time"
    fi
    
    # Parse file information for comfy.templates.json
    if echo "$output" | grep -q "comfy.templates.json:"; then
        local file="comfy.templates.json"
        local status=$(echo "$output" | grep -A 5 "comfy.templates.json:" | grep "STATUS:" | awk '{print $2}')
        local local_time=$(echo "$output" | grep -A 5 "comfy.templates.json:" | grep "Local:" | head -1 | sed 's/Local: //')
        local remote_time=$(echo "$output" | grep -A 5 "comfy.templates.json:" | grep "Remote:" | head -1 | sed 's/Remote: //')
        
        print_file_sync_status "$file" "$status" "$local_time" "$remote_time"
    fi
    
    # Check for sync completion
    if echo "$output" | grep -q "completed successfully"; then
        print_success "ComfyUI settings sync completed"
    else
        print_error "ComfyUI settings sync encountered an issue"
        echo -e "${GRAY}$(echo "$output" | tail -5)${NC}"
    fi
    sync_comfy_done=true
  fi
<<<<<<< HEAD
=======
  
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
>>>>>>> origin/feature/command-cleanup
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
  
  print_section "Setting Up Scheduled Tasks"
  print_status "Starting cron service..."
  service cron start > /dev/null 2>&1
  
  # Always start these core services
  print_status "Configuring core services..."
  (crontab -l 2>/dev/null | grep -q 'comfy-download/download_run.sh' || (crontab -l 2>/dev/null; echo '* * * * * /workspace/comfy-download/download_run.sh') | crontab -)
<<<<<<< HEAD
=======
  (crontab -l 2>/dev/null | grep -q 'comfy-download/backup_comfyui.sh' || (crontab -l 2>/dev/null; echo '*/30 * * * * /workspace/comfy-download/backup_comfyui.sh') | crontab -)
>>>>>>> origin/feature/command-cleanup
  (crontab -l 2>/dev/null | grep -q 'comfy-download/node_config_checker.sh' || (crontab -l 2>/dev/null; echo '0 */6 * * * /workspace/comfy-download/node_config_checker.sh apply') | crontab -)
  print_success "Core services configured"
  
  # Start workflow sync if specified
  if [ "$run_workflows" = "true" ]; then
<<<<<<< HEAD
    print_status "Configuring workflow sync service..."
    (crontab -l 2>/dev/null | grep -q 'comfy-download/bisync_comfyui.sh.*--workflows' || (crontab -l 2>/dev/null; echo '*/5 * * * * /workspace/comfy-download/bisync_comfyui.sh --workflows') | crontab -)
    print_success "Workflow synchronization service scheduled"
=======
    (crontab -l 2>/dev/null | grep -q 'bisync_comfyui.sh.*workflows' || (crontab -l 2>/dev/null; echo '*/5 * * * * /workspace/comfy-download/bisync_comfyui.sh workflows') | crontab -)
    echo "Workflow synchronization service started"
>>>>>>> origin/feature/command-cleanup
  fi
  
  # Start custom node sync if specified
  if [ "$run_nodes" = "true" ]; then
    print_status "Configuring custom node sync service..."
    (crontab -l 2>/dev/null | grep -q 'comfy-download/custom_sync.sh' || (crontab -l 2>/dev/null; echo '*/30 * * * * /workspace/comfy-download/custom_sync.sh') | crontab -)
    print_success "Custom node synchronization service scheduled"
  fi
  
  # Start ComfyUI settings sync if specified
  if [ "$run_comfy" = "true" ]; then
    print_status "Configuring ComfyUI settings sync service..."
    (crontab -l 2>/dev/null | grep -q 'comfy-download/bisync_comfyui.sh.*--comfy' || (crontab -l 2>/dev/null; echo '*/10 * * * * /workspace/comfy-download/bisync_comfyui.sh --comfy') | crontab -)
    print_success "ComfyUI settings synchronization service scheduled"
  fi
  
  # Start comfy settings sync if specified
  if [ "$run_comfy" = "true" ]; then
    (crontab -l 2>/dev/null | grep -q 'bisync_comfyui.sh.*comfy' || (crontab -l 2>/dev/null; echo '*/10 * * * * /workspace/comfy-download/bisync_comfyui.sh comfy') | crontab -)
    echo "ComfyUI settings synchronization service started"
  fi
}

case "$command" in
  start)
<<<<<<< HEAD
    # Display header
    print_section "ComfyUI Download Manager - Starting Services"
    print_status "Initializing services at $(get_formatted_time)"
    
    # Run node config checker
    print_section "Node Configuration Check"
    print_status "Verifying node configurations..."
    output=$(/workspace/comfy-download/node_config_checker.sh apply 2>&1)
    if echo "$output" | grep -q "Custom node configuration check completed"; then
      print_success "Node configurations verified"
    else
      print_warning "Node configuration check found issues:"
      echo -e "${GRAY}$(echo "$output" | tail -3)${NC}"
    fi
    
    # Run sync operations
=======
    # Show current time
    show_time
    
    # Run immediate operations
    echo "Starting services..."
    /workspace/comfy-download/backup_comfyui.sh force
    /workspace/comfy-download/node_config_checker.sh apply
>>>>>>> origin/feature/command-cleanup
    run_sync $options
    
    # Set up cron jobs
    start_cron_jobs $options
    
    # Final confirmation
    print_section "Startup Complete"
    print_success "All services have been started successfully!"
    ;;
  
  stop)
    print_section "ComfyUI Download Manager - Stopping Services"
    print_status "Removing scheduled tasks..."
    (crontab -l 2>/dev/null | grep -v 'comfy-download' | crontab -)
    print_success "All services stopped."
    ;;
  
  status)
<<<<<<< HEAD
    print_section "ComfyUI Download Manager - Status"
    print_status "Status as of $(get_formatted_time)"
=======
    # Show current time
    show_time
    
>>>>>>> origin/feature/command-cleanup
    TODAY=$(date +%Y-%m-%d)
    echo "Today: $TODAY"
    
    # Get log stats
    LOGS=$(cat /workspace/ComfyUI/logs/downloaded_$TODAY.log 2>/dev/null | wc -l)
    UNIQUE=$(sort /workspace/ComfyUI/logs/downloaded_$TODAY.log 2>/dev/null | uniq | wc -l)
    FILES=$(find /workspace/ComfyUI/output/$TODAY -type f -name "*.png" 2>/dev/null | wc -l)
    
    echo -e "${CYAN}Log entries:${NC} $LOGS"
    echo -e "${CYAN}Unique files downloaded:${NC} $UNIQUE"
    echo -e "${CYAN}Files in output folder:${NC} $FILES"

    # Add backup status information
    print_section "Backup Status"
    LAST_BACKUP=$(grep "Backup complete" /workspace/ComfyUI/logs/backup.log 2>/dev/null | tail -1)
    if [ -z "$LAST_BACKUP" ]; then
      print_warning "No backups recorded"
    else
      print_success "$LAST_BACKUP"
    fi

<<<<<<< HEAD
    # Add sync status information
    print_section "Sync Status"
=======
    # Add sync status information (all types)
    echo -e "\nSync status:"
>>>>>>> origin/feature/command-cleanup
    
    # Workflow sync
    LAST_SYNC=$(grep "sync completed successfully" /workspace/ComfyUI/logs/bisync.log 2>/dev/null | grep "workflows" | tail -1)
    if [ -z "$LAST_SYNC" ]; then
      print_warning "No successful workflow syncs recorded"
    else
      print_success "Workflows: $LAST_SYNC"
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
      print_warning "No custom node data syncs recorded"
    else
      print_success "Custom nodes: $LAST_CUSTOM_SYNC"
    fi
    
    # ComfyUI settings sync
    LAST_COMFY_SYNC=$(grep "ComfyUI settings sync completed" /workspace/ComfyUI/logs/bisync.log 2>/dev/null | tail -1)
    if [ -z "$LAST_COMFY_SYNC" ]; then
      print_warning "No ComfyUI settings syncs recorded"
    else
      print_success "ComfyUI settings: $LAST_COMFY_SYNC"
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
      print_section "Storage Information"
      WORKFLOW_SIZE=$(du -sh "/workspace/ComfyUI/user/default/workflows" | cut -f1)
      echo -e "${CYAN}Workflow directory size:${NC} $WORKFLOW_SIZE"
      if [[ "$WORKFLOW_SIZE" == *"G"* ]] || [[ "${WORKFLOW_SIZE%M}" -gt 50 ]]; then
        print_warning "Large workflow directory may slow down sync operations"
        print_warning "Consider archiving unused workflows elsewhere"
      fi
    fi
    ;;
  
  run)
    print_section "Manual Image Download"
    print_status "Processing new images..."
    output=$(/workspace/comfy-download/download_images.sh 2>&1)
    if echo "$output" | grep -q "Image download completed"; then
      print_success "Image download processed successfully"
    else
      print_warning "Image download details:"
      echo -e "${GRAY}$(echo "$output" | tail -3)${NC}"
    fi
    ;;
    
  backup)
    print_section "Manual Backup"
    print_status "Running backup operation..."
    output=$(/workspace/comfy-download/backup_comfyui.sh force 2>&1)
    if echo "$output" | grep -q "Backup complete"; then
      print_success "Backup completed successfully"
    else
      print_warning "Backup details:"
      echo -e "${GRAY}$(echo "$output" | tail -3)${NC}"
    fi
    ;;
    
  sync)
    print_section "Manual Synchronization"
    print_status "Running sync operations..."
    run_sync $options
    print_success "Manual sync completed"
    ;;
    
  checkconfig|cc)
    print_section "Node Configuration Check"
    if [ "$command" = "cc" ]; then
      # cc is the only alias we'll keep, but we'll still show a gentle reminder
      print_status "Note: 'cc' is an alias for 'checkconfig'"
    fi
    print_status "Checking and fixing node configurations..."
    output=$(/workspace/comfy-download/node_config_checker.sh apply 2>&1)
    if echo "$output" | grep -q "Custom node configuration check completed"; then
      print_success "Node configuration check completed"
    else
      print_warning "Node configuration details:"
      echo -e "${GRAY}$(echo "$output" | tail -3)${NC}"
    fi
    ;;
    
  report)
<<<<<<< HEAD
    print_section "ComfyUI Download System Report: $(get_formatted_time)"
=======
    # Show current time
    show_time
    
>>>>>>> origin/feature/command-cleanup
    TODAY=$(date +%Y-%m-%d)
    
    print_section "Download Statistics"
    LOGS=$(cat /workspace/ComfyUI/logs/downloaded_$TODAY.log 2>/dev/null | wc -l)
    UNIQUE=$(sort /workspace/ComfyUI/logs/downloaded_$TODAY.log 2>/dev/null | uniq | wc -l)
    FILES=$(find /workspace/ComfyUI/output/$TODAY -type f -name "*.png" 2>/dev/null | wc -l)
    
    echo -e "${CYAN}Log entries:${NC} $LOGS"
    echo -e "${CYAN}Unique files downloaded:${NC} $UNIQUE"
    echo -e "${CYAN}Files in output folder:${NC} $FILES"
    
    # Get backup information
    print_section "Backup Information"
    LAST_BACKUP=$(grep "Backup complete" /workspace/ComfyUI/logs/backup.log 2>/dev/null | tail -1)
    if [ -z "$LAST_BACKUP" ]; then
      print_warning "No backups recorded"
    else
      print_success "Latest backup: $LAST_BACKUP"
    fi
    BACKUP_COUNT=$(grep "Backup complete" /workspace/ComfyUI/logs/backup.log 2>/dev/null | grep -c "$(date +%Y-%m-%d)")
    echo -e "${CYAN}Backups today:${NC} $BACKUP_COUNT"
    
<<<<<<< HEAD
    # Get sync information
    print_section "Sync Status"
=======
    # Get sync information (all types)
    echo -e "\nSync Status:"
>>>>>>> origin/feature/command-cleanup
    
    # Workflow sync
    LAST_SYNC=$(grep "sync completed successfully" /workspace/ComfyUI/logs/bisync.log 2>/dev/null | grep "workflows" | tail -1)
    if [ -z "$LAST_SYNC" ]; then
      print_warning "No successful workflow syncs recorded"
    else
      print_success "Workflows: $LAST_SYNC"
    fi
<<<<<<< HEAD
    SYNC_COUNT=$(grep "sync completed successfully" /workspace/ComfyUI/logs/bisync.log 2>/dev/null | grep -c "$(date +%Y-%m-%d)")
    echo -e "${CYAN}Workflow syncs today:${NC} $SYNC_COUNT"
=======
    SYNC_COUNT=$(grep "sync completed successfully" /workspace/ComfyUI/logs/bisync.log 2>/dev/null | grep "workflows" | grep -c "$(date +%Y-%m-%d)")
    echo "  Workflow syncs today: $SYNC_COUNT"
>>>>>>> origin/feature/command-cleanup
    
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
      print_warning "No custom node data syncs recorded"
    else
      print_success "Custom nodes: $LAST_CUSTOM_SYNC"
    fi
    CUSTOM_SYNC_COUNT=$(grep "Custom node data sync process finished" /workspace/ComfyUI/logs/custom_sync.log 2>/dev/null | grep -c "$(date +%Y-%m-%d)")
    echo -e "${CYAN}Custom node syncs today:${NC} $CUSTOM_SYNC_COUNT"
    
    # ComfyUI settings sync
    LAST_COMFY_SYNC=$(grep "ComfyUI settings sync completed" /workspace/ComfyUI/logs/bisync.log 2>/dev/null | tail -1)
    if [ -z "$LAST_COMFY_SYNC" ]; then
      print_warning "No ComfyUI settings syncs recorded"
    else
      print_success "ComfyUI settings: $LAST_COMFY_SYNC"
    fi
    COMFY_SYNC_COUNT=$(grep "ComfyUI settings sync completed" /workspace/ComfyUI/logs/bisync.log 2>/dev/null | grep -c "$(date +%Y-%m-%d)")
    echo -e "${CYAN}ComfyUI settings syncs today:${NC} $COMFY_SYNC_COUNT"
    
    # Check storage usage
    print_section "Storage Usage"
    WORKFLOW_SIZE=$(du -sh "/workspace/ComfyUI/user/default/workflows" 2>/dev/null | cut -f1)
    echo -e "${CYAN}Workflow directory size:${NC} ${WORKFLOW_SIZE:-"N/A"}"
    OUTPUT_SIZE=$(du -sh "/workspace/ComfyUI/output/$TODAY" 2>/dev/null | cut -f1)
    echo -e "${CYAN}Today's output size:${NC} ${OUTPUT_SIZE:-"0B"}"
    
    # Check custom node data sizes
    STYLERHIGH_SIZE=$(du -sh "/workspace/comfy-data/milehighstyler" 2>/dev/null | cut -f1)
    PARAMS_SIZE=$(du -sh "/workspace/comfy-data/plushparameters" 2>/dev/null | cut -f1)
    PROMPTS_SIZE=$(du -sh "/workspace/comfy-data/plushprompts" 2>/dev/null | cut -f1)
    echo -e "${CYAN}MileHighStyler data size:${NC} ${STYLERHIGH_SIZE:-"0B"}"
    echo -e "${CYAN}Plush parameters size:${NC} ${PARAMS_SIZE:-"0B"}"
    echo -e "${CYAN}Plush prompts size:${NC} ${PROMPTS_SIZE:-"0B"}"
    ;;
  
  reset)
    print_section "Log Reset"
    TODAY=$(date +%Y-%m-%d)
    print_status "Backing up old log to downloaded_$TODAY.bak"
    cp /workspace/ComfyUI/logs/downloaded_$TODAY.log /workspace/ComfyUI/logs/downloaded_$TODAY.log.bak 2>/dev/null || true
    print_status "Cleaning log file"
    cat /workspace/ComfyUI/logs/downloaded_$TODAY.log.bak 2>/dev/null | sort | uniq > /workspace/ComfyUI/logs/downloaded_$TODAY.log 2>/dev/null || true
    print_success "Log file cleaned and optimized"
    ;;
  
  help|*)
    print_section "ComfyUI Download Manager - Command Reference"
    
<<<<<<< HEAD
    print_section "CORE COMMANDS"
    echo -e "${CYAN}dl start${NC}                   - Start all automated services"
    echo -e "  ${YELLOW}--workflows${NC} ${GREEN}(wf)${NC}        - Only start workflow sync services"
    echo -e "  ${YELLOW}--nodes${NC} ${GREEN}(nd)${NC}            - Only start custom node sync services"
    echo -e "  ${YELLOW}--comfy${NC} ${GREEN}(cf)${NC}            - Only start ComfyUI settings sync services"
    echo -e "${CYAN}dl stop${NC}                    - Stop all automated services"
    echo -e "${CYAN}dl status${NC}                  - Show current system status"
    echo -e "${CYAN}dl help${NC}                    - Display this help message"
    
    print_section "MANUAL OPERATIONS"
    echo -e "${CYAN}dl run${NC}                     - Process new images once"
    echo -e "${CYAN}dl backup${NC}                  - Run backup manually once"
    echo -e "${CYAN}dl sync${NC}                    - Run complete sync manually"
    echo -e "  ${YELLOW}--workflows${NC} ${GREEN}(wf)${NC}        - Sync only workflows"
    echo -e "  ${YELLOW}--nodes${NC} ${GREEN}(nd)${NC}            - Sync only custom nodes"
    echo -e "  ${YELLOW}--comfy${NC} ${GREEN}(cf)${NC}            - Sync only ComfyUI settings"
    echo -e "${CYAN}dl checkconfig${NC} (cc)        - Check and fix node configurations"
    
    print_section "UTILITIES"
    echo -e "${CYAN}dl report${NC}                  - Generate comprehensive system report"
    echo -e "${CYAN}dl reset${NC}                   - Clean up duplicate log entries"
=======
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
>>>>>>> origin/feature/command-cleanup
    ;;
esac