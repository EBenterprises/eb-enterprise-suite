#!/usr/bin/env bash

echo "=== 1. CHECKING REMOTE CONFIGURATION ==="
git remote -v

echo "=== 2. FETCHING LATEST REMOTE REFS ==="
git fetch origin 2>/dev/null || echo "Remote fetch skipped or offline."

echo "=== 3. CONFIRMING CURRENT ARCHIVE BRANCH ==="
echo "Current Branch: $(git branch --show-current)"
echo "Latest Commit: $(git log -1 --oneline)"

echo ""
echo "=== READY TO PUSH OR BACKUP ==="
echo "To push your absolute archive branch safely to GitHub, run:"
echo "  git push -u origin archive-all-projects-restoration"
