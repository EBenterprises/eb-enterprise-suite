#!/bin/bash
set -e

echo ""
echo "=========================================================="
echo "GitHub requires token authentication. Let's configure it."
echo "=========================================================="
echo ""

read -p "Enter your GitHub Username: " gh_user
read -p "Enter your Personal Access Token (PAT): " gh_token
read -p "Enter your Repository Name (e.g. secure-vault): " repo_name

# Configure remote with embedded token for automated auth
git remote remove origin 2>/dev/null || true
git remote add origin "https://${gh_user}:${gh_token}@github.com/${gh_user}/${repo_name}.git"

echo "[*] Pushing code to GitHub..."
git push -u origin main

echo "[*] Push successful!"
