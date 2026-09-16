#!/bin/bash
set -e

echo "[*] Checking GitHub CLI authentication status..."
if ! gh auth status >/dev/null 2>&1; then
    echo "[!] GitHub CLI is not authenticated."
    echo "[*] Please run 'gh auth login' interactively first (choose HTTPS and follow browser/token prompts), then re-run this script."
    exit 1
fi

REPO_NAME="secure-vault"

echo "[*] Creating repository '$REPO_NAME' using active GitHub CLI session..."
gh repo create "$REPO_NAME" --private --source=. --remote=origin --push || {
    echo "[*] Repository might already exist, linking and pushing..."
    git remote remove origin 2>/dev/null || true
    gh repo set-default "$REPO_NAME"
    git push -u origin main
}

echo "[*] Success! Code pushed to GitHub."
