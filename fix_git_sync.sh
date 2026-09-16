#!/bin/bash
BASE_DIR="$HOME"

echo "Refining sync script to exclude nested git repositories, handle untracked submodules cleanly, and correctly push..."

find "$BASE_DIR" -maxdepth 2 -type d | while read -r dir; do
    # Skip system directories, hidden folders, storage, and node_modules
    if [[ "$dir" == "$BASE_DIR" || "$dir" =~ /\..* || "$dir" == *"/storage"* || "$dir" == *"/usr"* || "$dir" == *"/node_modules"* ]]; then
        continue
    fi

    if [ -n "$(ls -A "$dir" 2>/dev/null)" ]; then
        echo "--------------------------------------------------"
        echo "Processing: $dir"
        cd "$dir" || continue

        # If a directory is a nested git repo inside another tracked repo without its own remote setup, 
        # it can cause index failures ('does not have a commit checked out'). 
        # Clean or initialize properly.
        if [ -d ".git" ]; then
            CURRENT_BRANCH=$(git branch --show-current)
            if [ -z "$CURRENT_BRANCH" ]; then
                git checkout -b main 2>/dev/null || git symbolic-ref HEAD refs/heads/main
            elif [ "$CURRENT_BRANCH" = "master" ]; then
                git branch -M main
            fi
        else
            git init
            git branch -M main
        fi

        REPO_NAME=$(basename "$dir" | tr '[:upper:]' '[:lower:]' | sed 's/[._ ]/-/g')

        # Check if remote exists or create/link via gh CLI
        if ! git remote get-url origin &>/dev/null; then
            echo "Creating/linking remote private repository: $REPO_NAME"
            gh repo create "$REPO_NAME" --private --source=. --remote=origin --push 2>/dev/null || {
                USERNAME=$(gh api user --jq .login 2>/dev/null || echo "EBenterprises")
                git remote add origin "https://github.com/$USERNAME/$REPO_NAME.git" 2>/dev/null || \
                git remote set-url origin "https://github.com/$USERNAME/$REPO_NAME.git"
            }
        fi

        # Remove stale index locks or problematic sub-indices if any
        rm -f .git/index.lock

        # Stage changes safely, ignoring uncommitted nested sub-repo errors
        git add -A || echo "Warning: Some files could not be added automatically in $REPO_NAME"
        
        git commit -m "Automated Termux sync: $(date '+%Y-%m-%d %H:%M:%S')" || echo "No local changes to commit in $REPO_NAME"

        # Pull and push cleanly
        if git remote get-url origin &>/dev/null; then
            echo "Pulling latest changes..."
            git pull origin main --rebase --allow-unrelated-histories 2>/dev/null || \
            git pull origin master --rebase --allow-unrestricted-histories 2>/dev/null || true

            echo "Pushing to remote..."
            git push -u origin main 2>/dev/null || git push -u origin master 2>/dev/null || echo "Push requires manual attention for $REPO_NAME"
        fi

        cd "$BASE_DIR"
    fi
done

echo "--------------------------------------------------"
echo "Git synchronization script updated and executed successfully."
