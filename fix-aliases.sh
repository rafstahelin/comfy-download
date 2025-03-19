# Edit your .bashrc file
nano ~/.bashrc

# Find the alias section and replace it with:

# Image download system function
dl() {
  if [ "$#" -eq 0 ]; then
    /workspace/comfy-download/dl-manager.sh help
  else
    /workspace/comfy-download/dl-manager.sh "$@"
  fi
}

# Save the file (Ctrl+O, Enter, Ctrl+X)
# Then source it
source ~/.bashrc