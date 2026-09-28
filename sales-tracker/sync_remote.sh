#!/bin/bash
set -e

echo "[+] Pulling latest remote changes with rebase..."
git pull origin main --rebase || echo "[!] Rebase encountered conflicts, please resolve manually if needed."

echo "[+] Staging remaining changes and adding untracked build artifacts..."
git add -A

echo "[+] Committing final workspace synchronization..."
git commit -m "chore: synchronize multi-instance cluster deployment and update remote tracking" || echo "Nothing to commit"

echo "[+] Pushing to remote repository..."
git push origin main

echo "[+] Repository successfully updated and synchronized."
