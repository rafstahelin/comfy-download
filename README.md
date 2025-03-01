# ComfyUI Download System

A simple system for automatically downloading ComfyUI output images to Dropbox (or any rclone destination) and tracking which files have been downloaded.

## Features

- Automatically downloads new images from ComfyUI's output folder
- Runs every 10 seconds via cron
- Tracks downloaded images to avoid duplicates
- Simple commands to manage the download system

## Requirements

- RunPod container with ComfyUI installed
- rclone configured with a Dropbox remote (or other destination)
- cron installed in the container

## Installation

1. Clone this repository to your RunPod container:

```bash
git clone https://github.com/yourusername/comfy-download.git
cd comfy-download
```

2. Run the setup script:

```bash
chmod +x setup.sh
./setup.sh
```

3. Start the download system:

```bash
start
```

## Commands

After installation, you'll have the following commands available:

| Command | Description |
|---------|-------------|
| `start` | Start the automatic download system |
| `stop` | Stop the automatic download system |
| `status` | Show current download statistics |
| `run` | Run a download check manually once |
| `reset` | Clean up duplicate entries in the log file |

## How It Works

- The system uses cron to run a check every minute
- Each check runs 6 times with a 10-second pause, ensuring new images are detected quickly
- Images are downloaded from `/workspace/ComfyUI/output/YYYY-MM-DD/` to your configured destination
- Downloaded files are tracked in a log file to avoid re-downloading

## Customization

You can modify the scripts to change:

- The source directory path (default: `/workspace/ComfyUI/output/YYYY-MM-DD/`)
- The destination path (default: `dbx:/studio/ai/output/output-eagle.library/output-eagle`)
- The check frequency (default: every 10 seconds)

Edit the `download_images.sh` file to change these settings.

## Logs

Logs are stored in the following locations:

- Download log: `/workspace/ComfyUI/logs/downloaded_YYYY-MM-DD.log`
- Cron execution log: `/workspace/ComfyUI/logs/cron.log`

## Troubleshooting

If you encounter issues:

1. Check if cron is running: `service cron status`
2. Verify your rclone configuration: `rclone config show`
3. Check the logs: `cat /workspace/ComfyUI/logs/cron.log`
4. Run the download script manually: `run`
5. Reset the log file if there are duplicates: `reset`