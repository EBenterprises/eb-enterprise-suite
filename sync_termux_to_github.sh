#!/bin/bash

# Ensure GitHub CLI and git are installed in Termux
if ! command -v gh &> /dev/null; then
    echo "Installing GitHub CLI..."
    pkg update && pkg install -y gh git
fi

if ! command -v git &> /dev/null; then
    pkg install -y git
fi

# Check GitHub authentication status
gh auth status || {
    echo "Please authenticate with GitHub:"
    gh auth login
}

# Define target workspace directory in Termux
BASE_DIR="$HOME"

echo "Scanning $BASE_DIR for projects and directories..."

find "$BASE_DIR" -maxdepth 2 -type d | while read -r dir; do
    # Skip system directories, hidden folders, and storage mounts
    if [[ "$dir" == "$BASE_DIR" || "$dir" =~ /\..* || "$dir" == *"/storage"* || "$dir" == *"/usr"* ]]; then
        continue
    fi

    # Check if directory contains files
    if [ -n "$(ls -A "$dir" 2>/dev/null)" ]; then
        echo "--------------------------------------------------"
        echo "Processing: $dir"
        cd "$dir" || continue

        # Format repository name (lowercase, replace spaces/underscores with hyphens)
        REPO_NAME=$(basename "$dir" | tr '[:upper:]' '[:lower:]' | sed 's/[._ ]/-/g')

        # Initialize git if not already initialized
        if [ ! -d ".git" ]; then
            git init
            git branch -M main
        fi

        # Create GitHub repository if it doesn't exist remotely
        if ! git remote get-url origin &>/dev/null; then
            echo "Creating private GitHub repository: $REPO_NAME"
            gh repo create "$REPO_NAME" --private --source=. --remote=origin --push 2>/dev/null || {
                echo "Repository may already exist on GitHub. Linking existing repo..."
                USERNAME=$(gh api user --jq .login)
                git remote add origin "https://github.com/$USERNAME/$REPO_NAME.git" 2>/dev/null || true
                git branch -u origin/main 2>/dev/null || git branch -u origin/master 2>/dev/null || true
            }
        fi

        # Stage, commit, and push updates
        git add .
        git commit -m "Automated Termux sync: $(date '+%Y-%m-%d %H:%M:%S')" || echo "No new changes to commit in $REPO_NAME"
        
        CURRENT_BRANCH=$(git branch --show-current)
        if [ -z "$CURRENT_BRANCH" ]; then
            CURRENT_BRANCH="main"
        fi
        
        git push -u origin "$CURRENT_BRANCH" || echo "Push completed or requires manual intervention for $REPO_NAME"
        
        cd "$BASE_DIR"
    fi
done

echo "--------------------------------------------------"
echo "Sync complete for all Termux directories."
