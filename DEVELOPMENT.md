# ComfyUI Download and Sync Manager - Development Guide

## Environment Overview

The ComfyUI Download Manager is designed to run in a RunPod environment with the following characteristics:

- **RunPod Instance**: Persistent storage GPU instance optimized for ML workloads
- **Environment**: Linux-based container with CUDA support
- **Development Interfaces**: SSH terminal, Jupyter Notebook, VSCode Server
- **Storage**: Network volume mounted to `/workspace` for persistence between sessions
- **GPU Access**: Direct access to NVIDIA GPUs for accelerated training and inference

## Project Architecture

The ComfyUI Download Manager is part of a larger ML workflow pipeline:

```
┌─────────────────┐                 ┌─────────────────┐
│ ML Training     │                 │ Inference & UI  │
│ ----------      │                 │ -----------     │
│ SimpleTuner     │────────────────▶│ ComfyUI         │
│ Easy (CLI)      │                 │ comfy-download  │
└─────────────────┘                 └─────────────────┘
```

### Related Projects

- `/workspace/easy/`: CLI wrapper for SimpleTuner training orchestration
- `/workspace/SimpleTuner/`: Core ML training framework (underlying engine)
- `/workspace/ComfyUI/`: Visual interface for model inference and testing
- `/workspace/comfy-download/`: ComfyUI workflow management and synchronization utilities (this repository)

## Development Workflow

### Setup

1. Connect to RunPod instance through your assigned URL
2. Use provided credentials for authentication
3. Select your preferred interface (Terminal, Jupyter, VSCode)
4. Default working directory is `/workspace`

### Common Development Tasks

- Modify script behavior in `*.sh` files
- Update sync configurations in bisync scripts
- Test changes with `./dl-manager.sh [command] [options]`
- Check logs in `/workspace/ComfyUI/logs/`

### Git Workflow

1. Create feature branches for development:
   ```bash
   git checkout -b feature/descriptive-name
   ```
2. Make focused, incremental changes
3. Commit changes with descriptive messages
4. Push changes to GitHub for review
5. Create pull requests for code review

### Testing

- Test synchronization with small test workflows
- Verify backup creation and restoration
- Validate automated downloading of generated images
- Test custom node configuration management

## Repository Structure

```
/workspace/comfy-download/
├── dl-manager.sh          # Main command interface
├── download_images.sh     # Image processing script
├── download_run.sh        # Cron job script
├── backup_comfyui.sh      # User settings backup script
├── bisync_comfyui.sh      # Workflow sync script
├── custom_sync.sh        # Custom node data sync script
├── node_config_checker.sh # Config validation script
├── setup.sh               # Installation script
└── fix-aliases.sh        # Alias management script
```

## Important Directories

- `/workspace/comfy-download/` - Scripts and configuration
- `/workspace/ComfyUI/output/YYYY-MM-DD/` - Generated images organized by date
- `/workspace/ComfyUI/logs/` - Download, backup, and sync logs
- `/workspace/ComfyUI/user/default/` - User settings synchronized with Dropbox
- `/workspace/comfy-data/` - Custom node data synchronized with Dropbox

## Current Development Priorities

- Implementing security enhancements outlined in issue #5
- Optimizing workflow synchronization for large workflow directories
- Improving cron job management for automated tasks