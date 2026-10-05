#!/usr/bin/env bash
set -e

PROJECT_DIR="$HOME/sales-tracker"
cd "$PROJECT_DIR"

echo "=== [1/4] Checking Local Git Remote Configuration ==="
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Git repository initialized."
    git remote -v
else
    echo "Initialising Git repository..."
    git init
    git remote add origin https://github.com/EBenterprises/sales-tracker.git
fi

echo ""
echo "=== [2/4] Fetching Remote Status & Tags ==="
git fetch origin --tags || echo "Note: Check network or GitHub authentication token if fetch failed."

echo ""
echo "=== [3/4] Comparing Local Files vs Remote Head ==="
git status --short

echo ""
echo "=== [4/4] Verifying Tracked Release Tags ==="
git tag -l

