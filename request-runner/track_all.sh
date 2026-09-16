#!/usr/bin/env bash
set -euo pipefail

echo "==> Configuring Git to track all files (including hidden and previously ignored artifacts)..."
git config --local core.excludesFile ""

# Force add everything in the repository workspace
git add -f .

echo "==> Current staged status for complete tracking:"
git status --short

echo "==> All files are now staged for tracking!"
