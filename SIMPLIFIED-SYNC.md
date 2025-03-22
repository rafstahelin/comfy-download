# Simplified Sync System Design

## Overview

This document outlines the simplified synchronization command structure for comfy-download. The primary goal is to maintain an intuitive, easy-to-use command interface while unifying the workflow and custom node synchronization features.

## Command Structure

### Core Principles

1. **Unity**: Treat synchronization as a single system with options rather than separate systems
2. **Simplicity**: Keep command syntax simple and consistent
3. **Compatibility**: Maintain backward compatibility with existing commands
4. **Extensibility**: Design for potential future sync targets

### Unified Commands

#### Primary Commands

| Command | Options | Description |
|---------|---------|-------------|
| `dl start` | `--all`, `--workflows`, `--nodes` | Start all services with optional sync targeting |
| `dl sync` | `--all`, `--workflows`, `--nodes` | Run manual sync with options |
| `dl status` |  | Show combined status for all services |
| `dl report` |  | Generate comprehensive report |

#### Compatibility Aliases

| Command | Equivalent To | Description |
|---------|---------------|-------------|
| `dl bisync` | `dl sync --workflows` | Sync only workflow data |
| `dl bi` | `dl sync --workflows` | Short alias for workflow sync |
| `dl customsync` | `dl sync --nodes` | Sync only custom node data |
| `dl cs` | `dl sync --nodes` | Short alias for node sync |

### Implementation Details

#### Options Behavior

- `--all` (default when no option specified): Sync both workflows and custom nodes
- `--workflows`: Sync only workflow-related data
- `--nodes`: Sync only custom node data

#### Command Processing

The `dl-manager.sh` script handles command parsing with a new `run_sync()` function that:

1. Processes command options
2. Determines which sync operations to run
3. Executes the appropriate sync scripts with necessary parameters

## Benefits

1. **Reduced Complexity**: Fewer unique commands to remember
2. **Consistent Interface**: Follows a predictable pattern
3. **Flexible Options**: Users can choose exactly what to synchronize
4. **Future-Proof**: Design supports adding additional sync targets later

## Transition Plan

1. **Immediate Implementation**: The new unified commands are deployed
2. **Maintain Aliases**: Keep existing command aliases for backward compatibility
3. **Documentation Update**: Update README and help text to showcase the unified approach
4. **Status/Report Unification**: Reorganize status and reporting to match the unified concept