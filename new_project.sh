#!/bin/bash
read -p "Enter new repository name: " REPO_NAME
if [ -z "$REPO_NAME" ]; then
    echo "Repository name cannot be empty."
    exit 1
fi

GITHUB_USER="ebenterprises"
GITHUB_TOKEN="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"

# 1. Automatically create the repo on GitHub
curl -s -H "Authorization: token $GITHUB_TOKEN" \
     -X POST \
     -d "{\"name\":\"$REPO_NAME\", \"private\":false}" \
     https://api.github.com/user/repos >/dev/null

# 2. Setup local directory and Git config
WORKSPACE_DIR="$HOME/workspace/$REPO_NAME"
mkdir -p "$WORKSPACE_DIR"
cd "$WORKSPACE_DIR" || exit 1

if [ ! -d ".git" ]; then
    git init -b main
    git remote add origin "https://${GITHUB_USER}:${GITHUB_TOKEN}@github.com/EBenterprises/${REPO_NAME}.git"
    git config user.name "Easton Bodeux"
    git config user.email "eastonbodeuxenterprises@gmail.com"
fi

# 3. Scaffold standard files
echo "# $REPO_NAME" > README.md
echo "echo 'Initializing $REPO_NAME...'" > run.sh
chmod +x run.sh

# 4. Initial commit and push
git add -A
git commit -m "Initialize $REPO_NAME" >/dev/null 2>&1
git push -u origin main >/dev/null 2>&1 &

echo "Repository '$REPO_NAME' successfully created, initialized, and linked to GitHub!"
