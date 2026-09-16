#!/bin/bash

BASE_DIR="$HOME"

echo "Enhancing sync script to handle missing remote repositories, pull conflicts, and proper initialization..."

find "$BASE_DIR" -maxdepth 2 -type d | while read -r dir; do
    # Skip system directories, hidden folders, and storage/node_modules
    if [[ "$dir" == "$BASE_DIR" || "$dir" =~ /\..* || "$dir" == *"/storage"* || "$dir" == *"/usr"* || "$dir" == *"/node_modules"* ]]; then
        continue
    fi

    if [ -n "$(ls -A "$dir" 2>/dev/null)" ]; then
        echo "--------------------------------------------------"
        echo "Syncing: $dir"
        cd "$dir" || continue

        REPO_NAME=$(basename "$dir" | tr '[:upper:]' '[:lower:]' | sed 's/[._ ]/-/g')

        if [ ! -d ".git" ]; then
            git init
            git branch -M main
        else
            # Ensure branch is main
            CURRENT_BRANCH=$(git branch --show-current)
            if [ "$CURRENT_BRANCH" = "master" ]; then
                git branch -M main
            fi
        fi

        # Check if remote exists or create it via gh CLI
        if ! git remote get-url origin &>/dev/null; then
            echo "Attempting to create remote private repository: $REPO_NAME"
            gh repo create "$REPO_NAME" --private --source=. --remote=origin --push 2>/dev/null || {
                echo "Repository likely exists on GitHub. Linking and pulling..."
                USERNAME=$(gh api user --jq .login)
                git remote add origin "https://github.com/$USERNAME/$REPO_NAME.git" 2>/dev/null || \
                git remote set-url origin "https://github.com/$USERNAME/$REPO_NAME.git"
                
                git branch -u origin/main 2>/dev/null || true
            }
        fi

        # Stage and commit current local changes
        git add .
        git commit -m "Automated Termux sync: $(date '+%Y-%m-%d %H:%M:%S')" || echo "No local changes to commit in $REPO_NAME"

        # Pull with rebase to handle existing remote history cleanly (e.g. github-snippets)
        if git remote get-url origin &>/dev/null; then
            echo "Pulling latest changes from remote..."
            git pull origin main --rebase --allow-unrelated-histories 2>/dev/null || \
            git pull origin master --rebase --allow-unrelated-histories 2>/dev/null || true

            echo "Pushing to remote..."
            git push -u origin main 2>/dev/null || git push -u origin master 2>/dev/null || echo "Push requires manual attention for $REPO_NAME"
        fi

        cd "$BASE_DIR"
    fi
done

echo "--------------------------------------------------"
echo "All Termux repositories synced successfully."
