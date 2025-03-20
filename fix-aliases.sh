#!/bin/bash

# This script ensures all comfy-download aliases are properly set up
# without conflicting with other repositories

# First, remove any existing problematic aliases
sed -i '/alias dl=/d' ~/.bashrc

# Now add the alias to .bashrc with clear comment markers
if ! grep -q '# BEGIN COMFY-DOWNLOAD ALIASES' ~/.bashrc; then
  cat >> ~/.bashrc << 'EOF'

# BEGIN COMFY-DOWNLOAD ALIASES
# These aliases are managed by the comfy-download repository
alias dl="bash /workspace/comfy-download/dl-manager.sh"
# END COMFY-DOWNLOAD ALIASES
EOF
fi

echo "Comfy-download aliases have been updated."
echo "Run 'source ~/.bashrc' to activate them in this session."
