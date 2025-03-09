# ComfyUI Download Manager

## Overview
The ComfyUI Download Manager is an integrated system that automatically monitors and processes generated images from ComfyUI. It works seamlessly with the Easy system, providing simple command-line aliases for managing your image downloads.

## Features
- Automatic monitoring of ComfyUI output directory
- Scheduled background processing using cron jobs
- Simple command-line interface for managing downloads
- Daily logging of downloaded images
- Automatic deduplication of download logs

## Installation
The download manager is automatically installed when you run the Easy setup script:
cd /workspace/easy
chmod +x setup.sh
bash setup.sh
source ~/.bashrc
Copy
## Usage
After installation, the following commands are available:

| Command | Description |
|---------|-------------|
| `dl start` | Start the automatic download system (activates cron job) |
| `dl stop` | Stop the automatic download system |
| `dl status` | Show current download statistics |
| `dl run` | Run a download check manually once |
| `dl reset` | Clean up duplicate entries in the log file |
| `dl help` | Display command reference |

## How It Works
1. When you run `dl start`, a cron job is set up to run every minute
2. The cron job executes the download script which checks for new images
3. Images are logged in `/workspace/ComfyUI/logs/downloaded_YYYY-MM-DD.log`
4. Statistics can be viewed at any time using the `dl status` command

## Requirements
- RunPod environment with ComfyUI installed
- Bash shell environment
- Cron service
For your requirements file, here's a simple specification you can use:
Copy# Requirements for ComfyUI Download Manager
cron
bash >= 4.0