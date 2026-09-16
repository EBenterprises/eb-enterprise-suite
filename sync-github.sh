#!/bin/bash
BRANCH="main"
COMMIT_MSG="auto-sync: update codebase state $(date '+%Y-%m-%d %H:%M:%S')"

echo "Staging current workspace changes..."
git add -A

if git diff-index --quiet HEAD --; then
    echo "No modifications detected."
else
    git commit -m "$COMMIT_MSG"
    git push origin "$BRANCH" || echo "Push skipped: Check remote origin URL."
    echo "Sync complete."
fi
