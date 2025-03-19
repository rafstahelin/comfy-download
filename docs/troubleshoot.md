# ComfyUI Download Manager - Troubleshooting Reference

## Monitoring Commands

### Check Cron Status
```bash
# Check if cron service is running
service cron status

# View scheduled cron jobs
crontab -l

# Check recent cron activity
grep CRON /var/log/syslog | tail -20
```

### Monitor Log Files
```bash
# Monitor download process
tail -f /workspace/ComfyUI/logs/cron.log

# Monitor bisync process
tail -f /workspace/ComfyUI/logs/bisync.log

# Monitor backup process
tail -f /workspace/ComfyUI/logs/backup.log
```

### Check Running Processes
```bash
# Watch for active processes in real-time
watch -n 1 "ps aux | grep -E 'download|bisync|backup'"

# Check all running processes
ps aux | grep comfy
```

### Generate System Report
```bash
# View comprehensive system report
dl report
```

## Common Issues

### Alias Commands Not Working
If you see errors like `invalid alias name` when using commands with spaces:

```bash
# Fix 1: Update .bashrc with proper function-based aliases
nano ~/.bashrc

# Add this at the end of the file:
dl() {
  if [ "$#" -eq 0 ]; then
    /workspace/comfy-download/dl-manager.sh help
  else
    /workspace/comfy-download/dl-manager.sh "$@"
  fi
}

# Then source it:
source ~/.bashrc
```

### Scripts Not Running
```bash
# Make sure all scripts are executable
chmod +x /workspace/comfy-download/*.sh

# Run scripts manually with debug output
bash -x /workspace/comfy-download/download_run.sh
bash -x /workspace/comfy-download/bisync_comfyui.sh
bash -x /workspace/comfy-download/backup_comfyui.sh
```

### File Permission Issues
```bash
# Check file permissions
ls -la /workspace/ComfyUI/output/

# Fix output directory permissions
chmod -R 755 /workspace/ComfyUI/output/
```

### Dropbox Connectivity
```bash
# Test Dropbox connection
rclone lsd dbx:

# Check rclone config
rclone config show

# Fix path issues in scripts
nano /workspace/comfy-download/bisync_comfyui.sh
# Ensure DEST_DIR is set to: dbx:/studio/ai/libs/comfy-data/default
```

### Large Workflow Directory
```bash
# Check workflow directory size
du -sh /workspace/ComfyUI/user/default/workflows

# Organize workflows to reduce size
dl organize

# Remove hidden files/directories
find /workspace/ComfyUI/user/default/workflows -name ".*" -type d -exec rm -rf {} \; 2>/dev/null
```

### Recovery Actions
```bash
# Force resync
dl bisync

# Reset download log
dl reset

# Restart all services
dl stop
dl start
```

## Quick Start

```bash
# Start all services
dl start

# Check status
dl report

# Run manual operations
dl run     # Check for images to download
dl backup  # Run manual backup
dl bi      # Run manual sync
```