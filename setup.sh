#!/bin/bash

# Make scripts executable in their repository location
chmod +x /workspace/comfy-download/download_images.sh
chmod +x /workspace/comfy-download/download_run.sh
chmod +x /workspace/comfy-download/backup_comfyui.sh
chmod +x /workspace/comfy-download/bisync_comfyui.sh
chmod +x /workspace/comfy-download/custom_sync.sh
chmod +x /workspace/comfy-download/node_config_checker.sh
chmod +x /workspace/comfy-download/dl-manager.sh
chmod +x /workspace/comfy-download/fix-aliases.sh

# Create logs directory
mkdir -p /workspace/ComfyUI/logs
# Create temporary backup directory
mkdir -p /tmp/comfyui-backup

# Create custom node data directories
mkdir -p /workspace/comfy-data/milehighstyler
mkdir -p /workspace/comfy-data/plushparameters
mkdir -p /workspace/comfy-data/plushprompts

# Create helper scripts directory
mkdir -p /workspace/bin

# Create simple script files instead of complex aliases
cat > /workspace/bin/dl-start.sh << 'EOF'
#!/bin/bash
service cron start
# Run backup immediately
/workspace/comfy-download/backup_comfyui.sh force
# Run bisync immediately to sync with latest settings from Dropbox
/workspace/comfy-download/bisync_comfyui.sh force
# Run node config checker
/workspace/comfy-download/node_config_checker.sh apply
# Run custom sync immediately
/workspace/comfy-download/custom_sync.sh force
# Set up cron jobs
(crontab -l 2>/dev/null | grep -q 'comfy-download/download_run.sh' || (crontab -l 2>/dev/null; echo '* * * * * /workspace/comfy-download/download_run.sh') | crontab -)
(crontab -l 2>/dev/null | grep -q 'comfy-download/backup_comfyui.sh' || (crontab -l 2>/dev/null; echo '0 * * * * /workspace/comfy-download/backup_comfyui.sh') | crontab -)
(crontab -l 2>/dev/null | grep -q 'comfy-download/bisync_comfyui.sh' || (crontab -l 2>/dev/null; echo '*/5 * * * * /workspace/comfy-download/bisync_comfyui.sh') | crontab -)
(crontab -l 2>/dev/null | grep -q 'comfy-download/custom_sync.sh' || (crontab -l 2>/dev/null; echo '*/30 * * * * /workspace/comfy-download/custom_sync.sh') | crontab -)
(crontab -l 2>/dev/null | grep -q 'comfy-download/node_config_checker.sh' || (crontab -l 2>/dev/null; echo '0 */6 * * * /workspace/comfy-download/node_config_checker.sh apply') | crontab -)
echo 'Image download, backup and bidirectional sync system started!'
EOF

cat > /workspace/bin/dl-stop.sh << 'EOF'
#!/bin/bash
(crontab -l 2>/dev/null | grep -v 'comfy-download' | crontab -)
echo 'Image download, backup and bidirectional sync system stopped!'
EOF

cat > /workspace/bin/dl-status.sh << 'EOF'
#!/bin/bash
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

# Add custom sync status information
echo -e "\nCustom node data sync status:"
LAST_CUSTOM_SYNC=$(grep "Custom node data sync process finished" /workspace/ComfyUI/logs/custom_sync.log 2>/dev/null | tail -1)
if [ -z "$LAST_CUSTOM_SYNC" ]; then
  echo "No custom node data syncs recorded"
else
  echo "$LAST_CUSTOM_SYNC"
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
EOF

cat > /workspace/bin/dl-backup.sh << 'EOF'
#!/bin/bash
/workspace/comfy-download/backup_comfyui.sh force
EOF

cat > /workspace/bin/dl-bisync.sh << 'EOF'
#!/bin/bash
/workspace/comfy-download/bisync_comfyui.sh force
EOF

cat > /workspace/bin/dl-customsync.sh << 'EOF'
#!/bin/bash
/workspace/comfy-download/custom_sync.sh force
EOF

cat > /workspace/bin/dl-checkconfig.sh << 'EOF'
#!/bin/bash
/workspace/comfy-download/node_config_checker.sh apply
EOF

cat > /workspace/bin/dl-reset.sh << 'EOF'
#!/bin/bash
TODAY=$(date +%Y-%m-%d)
echo "Backing up old log to downloaded_$TODAY.bak"
cp /workspace/ComfyUI/logs/downloaded_$TODAY.log /workspace/ComfyUI/logs/downloaded_$TODAY.log.bak 2>/dev/null || true
echo "Cleaning log file"
cat /workspace/ComfyUI/logs/downloaded_$TODAY.log.bak 2>/dev/null | sort | uniq > /workspace/ComfyUI/logs/downloaded_$TODAY.log 2>/dev/null || true
echo "Done."
EOF

cat > /workspace/bin/dl-help.sh << 'EOF'
#!/bin/bash
echo "Command Reference:"
echo "------------------"
echo "dl start      - Start the automatic download, backup and bidirectional sync system"
echo "dl stop       - Stop the automatic download, backup and bidirectional sync system"
echo "dl status     - Show current download, backup and sync statistics"
echo "dl report     - Generate a comprehensive report of today's operations"
echo "dl run        - Run a download check manually once"
echo "dl backup     - Run a backup manually once"
echo "dl bisync     - Run a bidirectional sync manually once"
echo "dl bi         - Alias for dl bisync"
echo "dl customsync - Run a custom node data sync manually once"
echo "dl cs         - Alias for dl customsync"
echo "dl checkconfig - Check and fix custom node configurations"
echo "dl cc         - Alias for dl checkconfig"
echo "dl reset      - Clean up duplicate log entries"
echo "dl help       - Display this help message"
EOF

# Make all scripts executable
chmod +x /workspace/bin/dl-*.sh

# Setup custom node configurations
/workspace/comfy-download/node_config_checker.sh apply

# Run our alias fix script
/workspace/comfy-download/fix-aliases.sh

# Inform the user
echo "Download, backup and bidirectional sync system scripts and alias have been created"
echo "Please run 'source ~/.bashrc' to activate them in this session"
echo