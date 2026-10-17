#!/usr/bin/env bash

echo "=== 1. REMOVING .git-credentials FROM WORKING TREE & INDEX ==="
git rm -f .git-credentials 2>/dev/null || rm -f .git-credentials
git reset HEAD .git-credentials 2>/dev/null || true

echo "=== 2. AMENDING CURRENT COMMIT TO EXCLUDE THE TOKEN ==="
git add -A
git commit --amend -m "chore(workspace): absolute restoration of all workspace projects, submodules, and historical data"

echo "=== 3. PUSHING CLEANED ARCHIVE TO GITHUB ==="
git push -u origin archive-all-projects-restoration

echo "=== DONE! ==="
