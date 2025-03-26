# AI Developer Guide for ComfyUI Download Manager

## Overview

This guide outlines the recommended workflow for using AI assistants (like Claude) to help with development of the ComfyUI Download Manager. It explains how to effectively leverage AI capabilities while working around limitations.

## AI Assistant Development Workflows

There are two primary workflows when using AI to assist with development:

### 1. Remote GitHub-based Workflow

In this workflow, Claude directly modifies code in the GitHub repository:

1. **Branch Creation**: Claude creates a feature branch
   ```
   Claude creates a new branch using GitHub API
   ```

2. **Code Implementation**: Claude writes code and pushes it to the branch
   ```
   Claude implements code and pushes using GitHub API
   ```

3. **Manual PR Creation**: You create a PR from Claude's branch
   ```
   You manually create a PR in GitHub's interface
   ```

4. **Review & Merge**: You review Claude's changes and merge if satisfied

5. **Local Testing**: Pull the changes to your RunPod environment
   ```bash
   git fetch
   git checkout main
   git pull
   # Test the changes
   ```

**Limitations**:
- Claude cannot create PRs due to API issues
- Some file operations may fail through the GitHub API

### 2. Local RunPod-based Workflow

In this workflow, Claude generates code that you paste into your local environment:

1. **Requirement Discussion**: Discuss the feature or fix needed

2. **Code Generation**: Claude generates the necessary code

3. **Local Implementation**: You copy-paste the code to your RunPod environment
   ```bash
   cd /workspace/comfy-download
   # Paste code into appropriate files
   ```

4. **Local Testing**: Test the changes directly
   ```bash
   ./dl-manager.sh [command] [options]
   ```

5. **Manual Commit**: If satisfied, commit and push the changes yourself
   ```bash
   git add .
   git commit -m "Description of changes"
   git push
   ```

**Advantages**:
- More direct control over code implementation
- Immediate testing feedback loop
- No API limitations

## Best Practices for AI Development

### 1. Contextual Information

When starting a new development session with Claude, provide:

- Link to the relevant repository
- Current feature branch being worked on
- Description of the task or feature
- References to any related issues or PRs

### 2. Code Review Prompting

When asking Claude to review code, provide:

- The file path
- The purpose of the code
- Specific aspects to focus on (performance, security, style, etc.)

### 3. Feature Implementation

When asking Claude to implement features:

- Break down complex features into smaller components
- Provide clear acceptance criteria
- Specify coding conventions to follow
- Reference similar existing features as examples

### 4. Testing Guidelines

When implementing tests:

- Test with small workflow files first
- Verify both local changes and Dropbox synchronization
- Check log files for proper output and error handling
- Test edge cases like interrupted syncs or empty directories

## Repository-Specific Guidelines

### Shell Script Development

When working with shell scripts:

- Follow POSIX compatibility guidelines when possible
- Include error handling for common failure conditions
- Use meaningful variable names and comments
- Always check return values of critical operations
- Maintain consistent formatting with existing code

### Synchronization Features

When working on sync capabilities:

- Consider bandwidth limitations and optimize transfers
- Implement appropriate conflict resolution strategies
- Add detailed logging for troubleshooting
- Design for graceful handling of interrupted operations
- Test with various file sizes and directory structures

### Cron Job Management

When working with scheduled tasks:

- Ensure proper installation and removal of cron jobs
- Avoid overlapping job execution for long-running operations
- Provide clear status reporting for scheduled tasks
- Design for robustness in case of system restarts

## Troubleshooting AI Integration

### GitHub API Issues

If Claude encounters issues with the GitHub API:

1. Verify the operation type (read vs. write)
2. Check the specific file paths being accessed
3. Consider falling back to the local workflow
4. For read-only operations, provide file contents directly in the chat

### Code Generation Issues

If Claude generates code that doesn't work:

1. Provide error messages and context
2. Ask for explanations of specific sections
3. Request alternative implementations
4. Break down complex requests into smaller parts