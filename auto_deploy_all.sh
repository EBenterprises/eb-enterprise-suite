#!/bin/bash

PROJECT_NAME="secure_vault"
echo "[+] Starting fully automated local setup, repo creation, and multi-remote deployment..."

# 1. Initialize git if not present
if [ ! -d ".git" ]; then
    git init
    git branch -M main
fi

# 2. Check if GitHub CLI (`gh`) is available and authenticated to create repos automatically
if command -v gh &> /dev/null && gh auth status &> /dev/null; then
    echo "[+] GitHub CLI detected and authenticated. Creating remote repositories automatically..."
    
    gh repo create "${PROJECT_NAME}_variant_a" --public --confirm 2>/dev/null || echo "[*] Variant A repository may already exist."
    gh repo create "${PROJECT_NAME}_variant_b" --public --confirm 2>/dev/null || echo "[*] Variant B repository may already exist."
    
    OWNER=$(gh api user --jq '.login')
    URL_A="https://github.com/$OWNER/${PROJECT_NAME}_variant_a.git"
    URL_B="https://github.com/$OWNER/${PROJECT_NAME}_variant_b.git"
    
    echo "[+] Generated URLs:"
    echo "    -> Variant A: $URL_A"
    echo "    -> Variant B: $URL_B"
else
    echo "[!] GitHub CLI (gh) not logged in or found. Falling back to organization convention..."
    URL_A="https://github.com/EBenterprises/${PROJECT_NAME}_variant_a.git"
    URL_B="https://github.com/EBenterprises/${PROJECT_NAME}_variant_b.git"
    echo "    -> Variant A: $URL_A"
    echo "    -> Variant B: $URL_B"
fi

# 3. Configure git remotes cleanly
git remote remove origin-a 2>/dev/null || true
git remote remove origin-b 2>/dev/null || true

git remote add origin-a "$URL_A"
git remote add origin-b "$URL_B"

# 4. Stage, commit, and tag current state
git add .
git commit -m "Automated full deployment snapshot: $(date)" 2>/dev/null || echo "[*] Working directory clean."
git tag -f "v1.0-auto"

# 5. Push to both remotes
echo "[+] Pushing to Variant A..."
git push -u origin-a main --tags

echo "[+] Pushing to Variant B..."
git push -u origin-b main --tags

echo "[+] Full automated deployment complete!"
