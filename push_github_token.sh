#!/bin/bash
set -e

echo "[*] Configuring credential store for secure authentication..."
git config --global credential.helper store

if ! git remote get-url origin > /dev/null 2>&1; then
    read -p "Enter your GitHub repository URL: " repo_url
    git remote add origin "$repo_url"
fi

echo ""
echo "=========================================================="
echo "NOTE: GitHub requires a Personal Access Token (PAT) instead"
echo "of your account password for command-line authentication."
echo "=========================================================="
echo ""

git push -u origin main
echo "[*] Push successful!"
