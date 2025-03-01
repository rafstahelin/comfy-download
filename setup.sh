#!/bin/bash

# Make scripts executable in their repository location
chmod +x /workspace/comfy-download/download_images.sh
chmod +x /workspace/comfy-download/download_run.sh

# Create logs directory
mkdir -p /workspace/ComfyUI/logs

# Create aliases
cat > /root/.bash_aliases << 'EOF'
# Image download system aliases
alias start="service cron start && (crontab -l 2>/dev/null | grep -q 'comfy-download' || (crontab -l 2>/dev/null; echo '* * * * * /workspace/comfy-download/download_run.sh') | crontab -) && echo 'Image download system started!'"
alias stop="(crontab -l 2>/dev/null | grep -v 'comfy-download' | crontab -) && echo 'Image download system stopped!'"
alias status="TODAY=\$(date +%Y-%m-%d); echo 'Today: '$TODAY; echo 'Log entries: '\$(cat /workspace/ComfyUI/logs/downloaded_\$TODAY.log 2>/dev/null | wc -l); echo 'Unique files downloaded: '\$(sort /workspace/ComfyUI/logs/downloaded_\$TODAY.log 2>/dev/null | uniq | wc -l); echo 'Files in output folder: '\$(find /workspace/ComfyUI/output/\$TODAY -type f -name \"*.png\" 2>/dev/null | wc -l)"
alias run="/workspace/comfy-download/download_images.sh"
alias reset="TODAY=\$(date +%Y-%m-%d); echo 'Backing up old log to downloaded_'\$TODAY'.bak'; cp /workspace/ComfyUI/logs/downloaded_\$TODAY.log /workspace/ComfyUI/logs/downloaded_\$TODAY.log.bak; echo 'Cleaning log file'; cat /workspace/ComfyUI/logs/downloaded_\$TODAY.log.bak | sort | uniq > /workspace/ComfyUI/logs/downloaded_\$TODAY.log; echo 'Done. Original had '\$(cat /workspace/ComfyUI/logs/downloaded_\$TODAY.log.bak | wc -l)' entries, cleaned has '\$(cat /workspace/ComfyUI/logs/downloaded_\$TODAY.log | wc -l)' entries.'"
alias dl-help="echo -e ' '\n| Command | Description |\n|---------|-------------|\n| start   | Start the automatic download system |\n| stop    | Stop the automatic download system |\n| status  | Show current download statistics |\n| run     | Run a download check manually once |\n| reset   | Clean up duplicate entries in the log file |\n| help    | Display this help message |\n''"
EOF

# Source aliases
source /root/.bash_aliases
echo "Setup complete! Use the following commands to manage your downloads:"
echo "start  - Start automatic downloads"
echo "stop   - Stop automatic downloads"
echo "status - Show download statistics"
echo "run    - Run one download check manually"
echo "reset  - Clean up duplicate log entries"
echo "help   - Display command reference"