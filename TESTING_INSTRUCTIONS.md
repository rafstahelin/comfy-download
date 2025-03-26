# Testing Instructions for Command Cleanup

## Overview

This document provides step-by-step instructions for testing the command system changes in the `feature/command-cleanup` branch. Follow these steps to verify that all functionality works as expected.

## Setup

1. Clone the repository (if you haven't already):
   ```bash
   cd /workspace
   git clone https://github.com/rafstahelin/comfy-download.git
   cd comfy-download
   ```

2. Switch to the feature branch:
   ```bash
   git fetch
   git checkout feature/command-cleanup
   ```

3. Make the scripts executable:
   ```bash
   chmod +x *.sh
   ```

## Automated Testing

Run the automated test script to check basic command functionality:

```bash
chmod +x test_commands.sh
./test_commands.sh
```

This will test most commands and save their output to `/tmp/dl-test-output/`. Review these outputs for any issues.

## Manual Testing Checklist

Follow this checklist to manually test each command:

### 1. Help Command

```bash
./dl-manager.sh help
```

Verify:
- [ ] Command output is organized into categories
- [ ] All commands are listed
- [ ] Deprecated commands are shown at the bottom

### 2. Status Command

```bash
./dl-manager.sh status
```

Verify:
- [ ] Shows download statistics
- [ ] Shows backup status
- [ ] Shows sync status for both workflows and custom nodes
- [ ] Shows workflow directory size

### 3. Sync Commands

Test each sync variation:

```bash
# Full sync
./dl-manager.sh sync

# Workflow sync only
./dl-manager.sh sync --workflows

# Custom node sync only
./dl-manager.sh sync --nodes
```

Verify:
- [ ] `sync` runs both workflow and custom node syncs
- [ ] `sync --workflows` only runs workflow sync
- [ ] `sync --nodes` only runs custom node sync

### 4. Deprecated Commands

Test the deprecated commands to ensure they still work but show warnings:

```bash
./dl-manager.sh bisync
./dl-manager.sh customsync
```

Verify:
- [ ] Commands still function correctly
- [ ] Deprecation warnings are displayed
- [ ] Suggested alternative commands are shown

### 5. Configuration Command

```bash
./dl-manager.sh checkconfig
./dl-manager.sh cc
```

Verify:
- [ ] Both commands perform the same function
- [ ] Only gentle reminder is shown for `cc` alias

### 6. Report Command

```bash
./dl-manager.sh report
```

Verify:
- [ ] Detailed report is generated
- [ ] All sections (download, backup, sync, storage) are included

### 7. Start/Stop Commands

**Important**: Only test these if you're ready to affect running services

```bash
# Test stop first so we don't disrupt existing services
./dl-manager.sh stop

# Then test start with various options
./dl-manager.sh start
./dl-manager.sh start --workflows
./dl-manager.sh start --nodes
```

Verify:
- [ ] `stop` removes all cron jobs related to comfy-download
- [ ] `start` sets up all cron jobs and runs initial syncs
- [ ] `start --workflows` only starts workflow-related cron jobs
- [ ] `start --nodes` only starts custom node-related cron jobs

## Comparison with Original Behavior

Switch back to the main branch to compare behavior:

```bash
git checkout main
```

Test the same commands and note any differences in behavior or output.

## Reporting Issues

If you encounter any issues, please document:

1. The command you ran
2. The expected behavior
3. The actual behavior
4. Any error messages received

## Next Steps

After successful testing:

1. Create a pull request to merge `feature/command-cleanup` into `main`
2. Update documentation with the new command structure
3. Consider adding the new command structure to any user guides