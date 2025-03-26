#!/bin/bash

# Test script for the dl-manager.sh command system
# This script tests each command and verifies its behavior

echo "ComfyUI Download Manager Command Testing"
echo "=========================================="
echo ""

# Location of the dl-manager.sh script
DL_MANAGER="./dl-manager.sh"

# Create test output directory
TEST_DIR="/tmp/dl-test-output"
mkdir -p "$TEST_DIR"

red() {
    echo -e "\033[0;31m$1\033[0m"
}

green() {
    echo -e "\033[0;32m$1\033[0m"
}

yellow() {
    echo -e "\033[0;33m$1\033[0m"
}

blue() {
    echo -e "\033[0;34m$1\033[0m"
}

# Function to test a command and capture output
test_command() {
    local cmd="$1"
    local expected_pattern="$2"
    local desc="$3"
    
    echo "$(blue "Testing: dl $cmd")"
    echo "Description: $desc"
    
    # Run the command and capture output
    output=$($DL_MANAGER $cmd 2>&1)
    echo "$output" > "$TEST_DIR/$cmd.out"
    
    # Check if output contains expected pattern
    if echo "$output" | grep -q "$expected_pattern"; then
        echo "$(green "✓ PASS: Output contains expected pattern")"
    else
        echo "$(red "✗ FAIL: Output does not contain expected pattern")"
        echo "Expected: $expected_pattern"
        echo "Output snippet: ${output:0:100}..."
    fi
    echo ""
}

# Test each command
echo "Testing Core Commands..."
echo "======================"

test_command "help" "ComfyUI Download Manager - Command Reference" "Help command should display the command reference"
test_command "status" "Today:" "Status command should show current system status"

# Prevent actual service changes during testing
echo "Note: Start/stop commands not fully tested to avoid service disruption"
echo ""

echo "Testing Manual Operations..."
echo "=========================="

test_command "sync --workflows" "Running workflow synchronization" "Sync with workflows flag should only sync workflows"
test_command "sync --nodes" "Running custom node data synchronization" "Sync with nodes flag should only sync custom nodes"
test_command "sync" "Running workflow synchronization" "Sync without flags should sync everything"
test_command "checkconfig" "Checking and fixing node configurations" "Checkconfig should check and fix node configurations"
test_command "cc" "Checking and fixing node configurations" "cc alias should run the checkconfig command"

echo "Testing Utilities..."
echo "==================="

test_command "report" "Download System Report" "Report command should generate a system report"

echo "Testing Deprecated Commands..."
echo "============================"

test_command "bisync" "deprecated" "Bisync command should show deprecation warning"
test_command "customsync" "deprecated" "Customsync command should show deprecation warning"

echo ""
echo "Test Results Summary"
echo "===================="
echo "All test outputs are available in: $TEST_DIR"
echo ""
echo "Next steps:"
echo "1. Review the test outputs in detail"
echo "2. Test the start/stop commands manually if needed"
echo "3. Test actual behavior of each command in the real environment"
echo "4. Report any issues or inconsistencies"
