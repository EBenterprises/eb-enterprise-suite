#!/bin/bash
set -e

if [ ! -d ".git" ]; then
    echo "[*] Initializing Git repository..."
    git init
    git branch -M main
fi

echo "[*] Adding project files..."
git add vault_core.py main.py buildozer.spec deploy_mobile.sh

echo "[*] Committing changes..."
git commit -m "Automated build: SecureVault mobile application infrastructure (Android/iOS core)" || echo "No changes to commit."

if ! git remote get-url origin > /dev/null 2>&1; then
    read -p "Enter your GitHub repository remote URL (e.g., https://github.com/username/secure-vault.git): " repo_url
    git remote add origin "$repo_url"
fi

echo "[*] Pushing to GitHub main..."
git push -u origin main

echo "[*] Push complete!"
