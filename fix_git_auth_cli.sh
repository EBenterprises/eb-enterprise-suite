#!/bin/bash
set -e

REPO_NAME="secure-vault"

echo "[*] Configuring Git to use GitHub CLI credentials automatically..."
gh auth setup-git

echo "[*] Ensuring remote is correctly configured..."
git remote remove origin 2>/dev/null || true
gh repo clone-or-link || true # fallback check or just add remote
git remote add origin "https://github.com/EBenterprises/${REPO_NAME}.git"

echo "[*] Pushing to GitHub using authenticated CLI session..."
git push -u origin main

echo "[*] Push complete!"
