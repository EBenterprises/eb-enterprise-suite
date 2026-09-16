#!/bin/bash
set -e

echo "[+] Initializing Git repository and preparing sync to GitHub..."

if [ ! -d ".git" ]; then
    git init
    git branch -M main
fi

# Add all files including releases and isolated instances
git add .

# Commit changes
git commit -m "EB Sales Tracker - Multi-Version Release Suite (v1-v5) with Full Isolation" || echo "[i] No new changes to commit."

echo "[+] Git commit complete."
echo "[i] To push to your GitHub repository, run the following commands:"
echo "    git remote add origin <YOUR_GITHUB_REPOSITORY_URL>"
echo "    git push -u origin main --tags"
