#!/bin/bash
REPO_NAME="my-new-project"
GITHUB_USER="ebenterprises"
GITHUB_TOKEN="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"

# 1. Create the remote repository on GitHub via API automatically
curl -s -H "Authorization: token $GITHUB_TOKEN" \
     -X POST \
     -d "{\"name\":\"$REPO_NAME\", \"private\":false}" \
     https://api.github.com/user/repos >/dev/null

# 2. Set up the local directory structure and initialize Git
mkdir -p "$HOME/workspace/$REPO_NAME"
cd "$HOME/workspace/$REPO_NAME" || exit 1

if [ ! -d ".git" ]; then
    git init -b main
    git remote add origin "https://${GITHUB_USER}:${GITHUB_TOKEN}@github.com/EBenterprises/${REPO_NAME}.git"
    git config user.name "Easton Bodeux"
    git config user.email "eastonbodeuxenterprises@gmail.com"
fi

# 3. Create initial project files
cat << 'EOT' > README.md
# $REPO_NAME
Automated infinite repository workspace.
EOT

cat << 'EOT' > app.py
print("Running $REPO_NAME...")
EOT

# 4. Initial commit and push
git add -A
git commit -m "Initialize $REPO_NAME" >/dev/null 2>&1
git push -u origin main >/dev/null 2>&1 &

echo "Repository '$REPO_NAME' created and synced automatically without opening GitHub."
