#!/bin/bash

# Make scripts executable in their repository location
chmod +x /workspace/comfy-download/download_images.sh
chmod +x /workspace/comfy-download/download_run.sh

# Create logs directory
mkdir -p /workspace/ComfyUI/logs

# Create helper scripts directory
mkdir -p /workspace/bin

# Create simple script files instead of complex aliases
cat > /workspace/bin/dl-start.sh << 'EOF'
#!/bin/bash
service cron start
(crontab -l 2>/dev/null | grep -q 'comfy-download' || (crontab -l 2>/dev/null; echo '* * * * * /workspace/comfy-download/download_run.sh') | crontab -)
echo 'Image download system started!'
EOF

cat > /workspace/bin/dl-stop.sh << 'EOF'
#!/bin/bash
(crontab -l 2>/dev/null | grep -v 'comfy-download' | crontab -)
echo 'Image download system stopped!'
EOF

cat > /workspace/bin/dl-status.sh << 'EOF'
#!/bin/bash
TODAY=$(date +%Y-%m-%d)
echo "Today: $TODAY"
echo "Log entries: $(cat /workspace/ComfyUI/logs/downloaded_$TODAY.log 2>/dev/null | wc -l)"
echo "Unique files downloaded: $(sort /workspace/ComfyUI/logs/downloaded_$TODAY.log 2>/dev/null | uniq | wc -l)"
echo "Files in output folder: $(find /workspace/ComfyUI/output/$TODAY -type f -name "*.png" 2>/dev/null | wc -l)"
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
echo "dl-start   - Start the automatic download system"
echo "dl-stop    - Stop the automatic download system"
echo "dl-status  - Show current download statistics"
echo "dl-run     - Run a download check manually once"
echo "dl-reset   - Clean up duplicate entries in the log file"
echo "dl-help    - Display this help message"
EOF

# Make all scripts executable
chmod +x /workspace/bin/dl-*.sh

# Create simple aliases in bashrc
cat >> ~/.bashrc << 'EOF'

# Image download system aliases
alias dl-start='/workspace/bin/dl-start.sh'
alias dl-stop='/workspace/bin/dl-stop.sh'
alias dl-status='/workspace/bin/dl-status.sh'
alias dl-run='/workspace/comfy-download/download_images.sh'
alias dl-reset='/workspace/bin/dl-reset.sh'
alias dl-help='/workspace/bin/dl-help.sh'
EOF

# Inform the user
echo "Download system scripts and aliases have been created"
echo "Please run 'source ~/.bashrc' to activate them in this session"
echo
echo "Setup complete! Use the following commands to manage your downloads:"
echo "dl-start  - Start automatic downloads"
echo "dl-stop   - Stop automatic downloads"
echo "dl-status - Show download statistics"
echo "dl-run    - Run one download check manually"
echo "dl-reset  - Clean up duplicate log entries"
echo "dl-help   - Display command reference"