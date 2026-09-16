#!/bin/bash
PROJECT_NAME="secure_vault"
echo "[+] Committing dashboard updates and pushing to GitHub repositories..."

# 1. Stage and commit updated index.html
git add index.html
git commit -m "Update live public dashboard view: $(date)" || echo "[*] Working tree up to date."

# 2. Push to Variant A and Variant B
echo "[+] Pushing to Variant A..."
git push -u origin-a main --force --tags

echo "[+] Pushing to Variant B..."
git push -u origin-b main --force --tags

echo "[+] Success! Repositories synchronized and public pages updating."
