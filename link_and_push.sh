#!/bin/bash
set -e

REPO_NAME="secure-vault"
GH_USER="EBenterprises"

echo "[*] Adding remote origin manually..."
git remote remove origin 2>/dev/null || true
git remote add origin "https://github.com/${GH_USER}/${REPO_NAME}.git"

echo "[*] Pushing branch to GitHub..."
git push -u origin main

echo "[*] Push complete!"
