#!/bin/bash

# Configuration
PROJECT_NAME="secure_vault"
echo "[+] Starting clean fix and multi-remote deployment for $PROJECT_NAME..."

if [ ! -d ".git" ]; then
    echo "[-] Error: Git repository not initialized. Running git init..."
    git init
    git branch -M main
fi

# Clean up incorrect dummy remotes if they were set to "A" or "B"
git remote remove origin-a 2>/dev/null || true
git remote remove origin-b 2>/dev/null || true

# Prompt user for actual valid GitHub repository URLs
echo ""
read -p "Enter valid HTTPS URL for Variant A (e.g., https://github.com/EBenterprises/secure_vault_a.git): " URL_A
read -p "Enter valid HTTPS URL for Variant B (e.g., https://github.com/EBenterprises/secure_vault_b.git): " URL_B

if [[ "$URL_A" != http* ]] || [[ "$URL_B" != http* ]]; then
    echo "[-] Error: Invalid URLs provided. Must start with https://"
    exit 1
fi

# Add clean remotes
git remote add origin-a "$URL_A"
git remote add origin-b "$URL_B"

# Stage, commit, and tag current state
git add .
git commit -m "Snapshot: Final state sync for multi-remote split test at $(date)" 2>/dev/null || echo "[*] Working tree clean, proceeding to tag/push..."
git tag -f "v1.0-final"

echo "[+] Pushing Variant A..."
git push -u origin-a main --tags

echo "[+] Pushing Variant B..."
git push -u origin-b main --tags

echo "[+] Success! Both repositories are now synchronized with the exact local state."
