#!/bin/bash

# ==============================================================================
# E&B ENTERPRISES - AUTOMATED GITHUB REPOSITORY INITIALIZATION & PUSH SUITE
# Organization: EBenterprises
# Repository: eb-enterprise-suite
# ==============================================================================

set -e

echo "[*] Checking for GitHub CLI (gh)..."
if command -v gh &> /dev/null; then
    echo "[*] GitHub CLI detected. Authenticating / verifying login status..."
    gh auth status || gh auth login

    echo "[*] Creating remote repository 'EBenterprises/eb-enterprise-suite' (if it doesn't already exist)..."
    gh repo create EBenterprises/eb-enterprise-suite --public --confirm 2>/dev/null || echo "[*] Repository may already exist. Proceeding..."
else
    echo "[!] GitHub CLI (gh) not installed. Please create the repository 'eb-enterprise-suite'"
    echo "    under the organization 'EBenterprises' manually at https://github.com/organizations/EBenterprises/repositories/new"
    echo "    Once created, run: git push -u origin main --force"
    exit 1
fi

echo "[*] Ensuring remote URL is correct..."
git remote remove origin 2>/dev/null || true
git remote add origin https://github.com/EBenterprises/eb-enterprise-suite.git

echo "[*] Executing force push to GitHub..."
git branch -M main
git push -u origin main --force

echo "=========================================================================="
echo "SUCCESS: Repository created and enterprise suite successfully pushed!"
echo "=========================================================================="
