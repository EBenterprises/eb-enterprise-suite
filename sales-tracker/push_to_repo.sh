#!/bin/bash
set -e

REPO_URL="https://github.com/EBenterprises/sales-tracker.git"

echo "[+] Linking remote repository: $REPO_URL"
git remote remove origin 2>/dev/null || true
git remote add origin "$REPO_URL"

echo "[+] Pulling remote changes with rebase to integrate history..."
git pull origin main --rebase || git pull origin main --allow-unrelated-histories --no-rebase || true

echo "[+] Ensuring branch is set to main..."
git branch -M main

echo "[+] Pushing code, releases, and tags to GitHub..."
git push -u origin main --tags

echo "[+] Successfully pushed to GitHub!"
