#!/usr/bin/env bash
set -euo pipefail

WORKSPACE_DIR="${HOME}/termux_workspace"
REPO_NAME="termux-workspace-backup"
VISUAL_MODE="private"

cd "$WORKSPACE_DIR"

if ! command -v gh &> /dev/null; then
    echo "GitHub CLI (gh) is not installed. Please install it using: pkg install gh"
    exit 1
fi

if ! gh auth status &> /dev/null; then
    echo "Please authenticate with GitHub first using: gh auth login"
    exit 1
fi

if ! git remote get-url origin &> /dev/null; then
    echo "Creating remote GitHub repository: ${REPO_NAME}..."
    gh repo create "$REPO_NAME" --"$VISUAL_MODE" --source=. --remote=origin --push
else
    echo "Remote origin already exists. Pushing latest changes..."
    git push -u origin main
fi

echo "Repository successfully synchronized with GitHub."
