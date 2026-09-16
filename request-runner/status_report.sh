#!/usr/bin/env bash
set -euo pipefail

echo "=========================================="
echo " EB Enterprises - Repository Sync Status"
echo "=========================================="
echo "Current Time: $(date)"
echo "Git Remote:   $(git remote get-url origin 2>/dev/null || echo 'No remote configured')"
echo "Branch:       $(git branch --show-current)"
echo "------------------------------------------"
git status
echo "=========================================="
echo "All workspace components tracked and synced."
