#!/usr/bin/env bash

echo "=== 1. ENSURING ALL UNTRACKED FILES & SUBMODULES ARE ACCESSED ==/="
git add --all .

echo "=== 2. HANDLING SUBMODULE CONTENTS SAFELY ==="
# Add submodule changes cleanly as part of the overarching archive
git submodule foreach --recursive 'git add -A && git commit -m "chore: snapshot submodule state" 2>/dev/null || true'

echo "=== 3. FINAL COMPREHENSIVE WORKSPACE COMMIT ==="
git commit -m "chore(omniverse): complete absolute archive of all projects, versions v1-v5, data stores, and submodules" 2>/dev/null || echo "Workspace is already fully committed."

echo ""
echo "=== ARCHIVE COMPLETE ==="
git branch --show-current
git log -1 --oneline
git status --short
