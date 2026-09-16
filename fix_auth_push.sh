#!/bin/bash
set -e

echo "[*] Configuring Git credential helper..."
git config --global credential.helper store

# Ensure token is used correctly via credential store or token-based remote URL
read -p "Enter your GitHub Username (e.g. ebenterprises): " gh_user
read -p "Enter your Personal Access Token (PAT): " gh_token
read -p "Enter your Repository Name (e.g. secure-vault): " repo_name

# Clear existing remotes
git remote remove origin 2>/dev/null || true

# Format URL with git:token for HTTPS basic auth
git remote add origin "https://${gh_token}@github.com/${gh_user}/${repo_name}.git"

echo "[*] Pushing to GitHub repository..."
git push -u origin main

echo "[*] Push successful!"
