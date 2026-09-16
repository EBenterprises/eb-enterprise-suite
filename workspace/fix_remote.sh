#!/bin/bash
WORKSPACE_DIR="$HOME/workspace"
GITHUB_USER="ebenterprises"
GITHUB_TOKEN="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"

# Fix root workspace repository remote to point to a valid repo or clean it up
cd "$WORKSPACE_DIR" || exit 1
git remote remove origin 2>/dev/null
git remote add origin "https://${GITHUB_USER}:${GITHUB_TOKEN}@github.com/${GITHUB_USER}/workspace-vault.git"

# Iterate through sub-repositories and ensure their remotes match their directory names
for repo in "$WORKSPACE_DIR"/*/; do
    if [ -d "${repo}.git" ]; then
        repo_name=$(basename "$repo")
        cd "$repo" || continue
        git remote remove origin 2>/dev/null
        git remote add origin "https://${GITHUB_USER}:${GITHUB_TOKEN}@github.com/${GITHUB_USER}/${repo_name}.git"
        echo "Configured remote for $repo_name"
    fi
done

echo "Remotes updated successfully."
