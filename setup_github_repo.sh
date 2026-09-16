#!/usr/bin/env bash
set -e

REPO_NAME="github-snippets"
REPO_DIR="${HOME}/${REPO_NAME}"

cd "$REPO_DIR"

echo "[+] Checking for GitHub CLI (gh)..."
if ! command -v gh &>/dev/null; then
    echo "[-] GitHub CLI (gh) is not installed. Please install it or create the repository manually."
    exit 1
fi

echo "[+] Authenticating with GitHub if needed..."
if ! gh auth status &>/dev/null; then
    gh auth login
fi

echo "[+] Creating remote repository '${REPO_NAME}' on GitHub via gh CLI..."
gh repo create "$REPO_NAME" --public --source=. --remote=origin --push || {
    echo "[!] Repository might already exist. Linking remote..."
    git remote remove origin 2>/dev/null || true
    GH_USER=$(gh api user --jq '.login')
    git remote add origin "git@github.com:${GH_USER}/${REPO_NAME}.git"
    git push -u origin main
}

echo "[✓] Remote repository successfully created and connected!"
