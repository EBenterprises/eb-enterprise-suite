#!/bin/bash

# Configuration
PROJECT_NAME="secure_vault"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
VERSION_TAG="v1.0-snapshot-$TIMESTAMP"

echo "[+] Initializing state preservation for $PROJECT_NAME..."

# Ensure git repository is initialized
if [ ! -d ".git" ]; then
    git init
    git branch -M main
fi

# Stage and commit current working state
git add .
git commit -m "Snapshot: Locking exact current state prior to fork sync at $(date)"

# Tag the stable baseline locally
git tag "$VERSION_TAG"
echo "[+] Local baseline locked with tag: $VERSION_TAG"

# Automation for GitHub syncing and forking
echo "[+] To push this exact snapshot to GitHub repositories for split-testing:"
echo "    1. Create two separate remote repositories on GitHub (e.g., secure_vault_variant_a and secure_vault_variant_b)."
echo "    2. Run the following commands to link and push:"
echo ""
echo "       git remote add origin-a <URL_FOR_VARIANT_A>"
echo "       git push -u origin-a main --tags"
echo ""
echo "       git remote add origin-b <URL_FOR_VARIANT_B>"
echo "       git push -u origin-b main --tags"
echo ""
echo "[+] State fully preserved locally and ready for multi-remote GitHub split-testing!"
