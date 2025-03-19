#!/bin/bash

# Make scripts executable in their repository location
chmod +x /workspace/comfy-download/download_images.sh
chmod +x /workspace/comfy-download/download_run.sh
chmod +x /workspace/comfy-download/backup_comfyui.sh
chmod +x /workspace/comfy-download/bisync_comfyui.sh
chmod +x /workspace/comfy-download/dl-manager.sh

# Create logs directory
mkdir -p /workspace/ComfyUI/logs
# Create temporary backup directory
mkdir -p /tmp/comfyui-backup

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
# Set up cron jobs
(crontab -l 2>/dev/null | grep -q 'comfy-download/download_run.sh' || (crontab -l 2>/dev/null; echo '* * * * * /workspace/comfy-download/download_run.sh') | crontab -)
(crontab -l 2>/dev/null | grep -q 'comfy-download/backup_comfyui.sh' || (crontab -l 2>/dev/null; echo '0 * * * * /workspace/comfy-download/backup_comfyui.sh') | crontab -)
(crontab -l 2>/dev/null | grep -q 'comfy-download/bisync_comfyui.sh' || (crontab -l 2>/dev/null; echo '*/5 * * * * /workspace/comfy-download/bisync_comfyui.sh') | crontab -)
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
EOF

# Make all scripts executable
chmod +x /workspace/bin/dl-*.sh

# First remove any existing problematic aliases
sed -i '/alias "dl /d' ~/.bashrc

# Now add the single correct alias to .bashrc
if ! grep -q 'alias dl="bash /workspace/comfy-download/dl-manager.sh"' ~/.bashrc; then
  cat >> ~/.bashrc << 'EOF'

# Image download system alias
alias dl="bash /workspace/comfy-download/dl-manager.sh"
EOF
fi

# Inform the user
echo "Download, backup and bidirectional sync system scripts and alias have been created"
echo "Please run 'source ~/.bashrc' to activate them in this session"
echo
echo "Setup complete! Use the following commands to manage your downloads and backups:"
echo "dl start  - Start automatic downloads, backups and bidirectional sync"
echo "dl stop   - Stop automatic downloads, backups and bidirectional sync"
echo "dl status - Show download, backup and sync statistics"
echo "dl report - Generate a comprehensive report of today's operations"
echo "dl run    - Run one download check manually"
echo "dl backup - Run one backup manually"
echo "dl bisync - Run one bidirectional sync manually (alias: dl bi)"
echo "dl reset  - Clean up duplicate log entries"
echo "dl help   - Display command reference"