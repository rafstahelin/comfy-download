#!/bin/bash

echo "ComfyUI Download Manager - Setup"
echo "================================"

# Make scripts executable in their repository location
chmod +x /workspace/comfy-download/*.sh

# Create required directories
mkdir -p /workspace/ComfyUI/logs
mkdir -p /tmp/comfyui-backup

# Create custom node data directories
mkdir -p /workspace/comfy-data/milehighstyler
mkdir -p /workspace/comfy-data/plushparameters
mkdir -p /workspace/comfy-data/plushprompts

# Create default ComfyUI user directories if not exist
mkdir -p /workspace/ComfyUI/user/default/workflows
touch /workspace/ComfyUI/user/default/comfy.settings.json
touch /workspace/ComfyUI/user/default/comfy.templates.json

# Set up rclone configuration if needed
mkdir -p ~/.config/rclone
if [ -f /workspace/rclone.conf ]; then
  cp /workspace/rclone.conf ~/.config/rclone/
  echo "✓ Rclone configuration set up successfully"
else
  echo "⚠ Warning: /workspace/rclone.conf not found. Rclone setup skipped."
  echo "  Please place your rclone.conf file in /workspace/ before using sync features."
fi

# Test rclone configuration
if rclone lsd dbx: > /dev/null 2>&1; then
  echo "✓ Dropbox connection verified successfully"
else
  echo "⚠ Warning: Cannot connect to Dropbox. Please check rclone configuration."
  echo "  To set up rclone, run 'rclone config' and create a 'dbx:' remote."
fi

# Run node configuration checker
/workspace/comfy-download/node_config_checker.sh apply

# Fix aliases
/workspace/comfy-download/fix-aliases.sh

# Run a manual backup to ensure everything is set up correctly
if rclone lsd dbx: > /dev/null 2>&1; then
  echo "\nRunning initial backup test..."
  /workspace/comfy-download/backup_comfyui.sh
  
  if [ $? -eq 0 ]; then
    echo "✓ Initial backup test successful"
  else
    echo "⚠ Initial backup test failed. Please check logs."
  fi
fi

# Final instructions
echo "\n✓ Setup completed!"
echo "\nTo activate the command aliases, run:"
echo "  source ~/.bashrc"
echo "\nTo start all services, run:"
echo "  dl start"
echo "\nTo see all available commands, run:"
echo "  dl help"