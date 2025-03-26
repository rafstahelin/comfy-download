# Command System Cleanup Project Checklist

## Overview of Changes

We've significantly improved the comfy-download repository in the `feature/command-cleanup` branch with:

### 1. Reorganized Command Structure
- Commands grouped into logical categories (Core, Manual Operations, Utilities)
<<<<<<< HEAD
- Added local time display in status outputs
=======
- Added local time zone display in status outputs
>>>>>>> origin/feature/command-cleanup
- Added `--comfy` option for managing settings/templates files separately
- Standardized option handling and improved help messages

### 2. Enhanced Sync Management
- Separated sync into distinct modes (workflows, comfy, nodes)
- Updated bisync_comfyui.sh to support individual sync modes
- Improved logging with more informative output

### 3. Setup and Documentation
- Added rclone configuration to setup.sh
- Created comprehensive testing instructions and tools
- Updated README with the new command structure

## Testing Checklist

### Initial Setup
- [ ] Check out the feature branch: `git checkout feature/command-cleanup`
- [ ] Make all scripts executable: `chmod +x *.sh`
- [ ] Run the setup script: `./setup.sh`
- [ ] Source bashrc: `source ~/.bashrc`

### Core Commands
- [ ] `dl help` - Verify new formatted help output
<<<<<<< HEAD
- [ ] `dl status` - Check if it displays correct information
=======
- [ ] `dl status` - Check if it shows local time correctly
>>>>>>> origin/feature/command-cleanup
- [ ] `dl start` - Verify it initializes all services
- [ ] `dl start --workflows` - Verify it only starts workflow sync
- [ ] `dl start --nodes` - Verify it only starts node sync
- [ ] `dl start --comfy` - Verify it only starts settings sync
- [ ] `dl stop` - Verify it stops all services

### Sync Commands
- [ ] `dl sync` - Test if it runs all sync operations
- [ ] `dl sync --workflows` - Test workflow-only sync
- [ ] `dl sync --nodes` - Test node-only sync
- [ ] `dl sync --comfy` - Test settings-only sync
- [ ] Verify warnings show for deprecated commands (bisync, customsync)

### Other Commands
- [ ] `dl backup` - Test manual backup
- [ ] `dl run` - Test manual image processing
- [ ] `dl checkconfig` - Test node config verification
- [ ] `dl report` - Verify comprehensive report output

### Edge Cases
- [ ] Test system with no existing workflows folder
- [ ] Test with missing rclone configuration
- [ ] Test with large workflow directory

<<<<<<< HEAD
=======
## Time Zone Handling Improvements

Instead of hardcoding "Panama" time, implement a better approach to detect the user's local time zone:

- [ ] Modify dl-manager.sh to get time zone from the system or environment
- [ ] Use a more generic time zone display format
- [ ] Consider adding the actual time zone name to output (e.g., EST, PST)

>>>>>>> origin/feature/command-cleanup
## Final Merge Steps
- [ ] Address any issues found during testing
- [ ] Update documentation with any additional findings
- [ ] Create a final PR summary with all changes and improvements
- [ ] Merge to main when all tests pass

## Future Improvements
<<<<<<< HEAD
=======
- [ ] Add support for custom time zone configuration
>>>>>>> origin/feature/command-cleanup
- [ ] Add enhanced error reporting and recovery options
- [ ] Consider adding a config file for customizing sync directories
- [ ] Add more visualization of sync status and progress