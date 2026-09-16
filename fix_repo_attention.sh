#!/bin/bash
TARGET_REPO="$HOME/github-snippets"

if [ -d "$TARGET_REPO" ]; then
    echo "Resolving manual attention required for: github-snippets"
    cd "$TARGET_REPO" || exit 1

    # Ensure we are on main
    CURRENT_BRANCH=$(git branch --show-current)
    if [ -z "$CURRENT_BRANCH" ]; then
        git checkout -b main 2>/dev/null || git symbolic-ref HEAD refs/heads/main
    elif [ "$CURRENT_BRANCH" = "master" ]; then
        git branch -M main
    fi

    # Handle detached HEAD or index locks
    rm -f .git/index.lock

    # Stage any remaining files
    git add -A

    # Check status and resolve divergent branches or auth/upstream configuration
    if ! git diff-index --quiet HEAD -- 2>/dev/null || [ -n "$(git status --porcelain)" ]; then
        git commit -m "Resolve manual attention sync: $(date '+%Y-%m-%d %H:%M:%S')"
    fi

    # Fetch and reconcile upstream/origin
    if git remote get-url origin &>/dev/null; then
        echo "Reconciling with origin/main..."
        git pull origin main --rebase --allow-unrelated-histories 2>/dev/null || true
        git push -u origin main 2>/dev/null || {
            echo "Attempting force-with-lease push if branches diverged..."
            git push -u origin main --force-with-lease
        }
    else
        echo "No origin remote configured for github-snippets."
    fi

    cd "$HOME"
    echo "github-snippets successfully resolved and synced."
else
    echo "Repository directory $TARGET_REPO not found."
fi
