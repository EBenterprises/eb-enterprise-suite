#!/bin/bash

# Configuration
PROJECT_NAME="secure_vault"
VERSION_TAG="v1.0-stable-$(date +%Y%m%d_%H%M%S)"
SPLIT_DIR_A="../${PROJECT_NAME}_variant_a"
SPLIT_DIR_B="../${PROJECT_NAME}_variant_b"

echo "[+] Initializing state preservation for $PROJECT_NAME..."

# Ensure git repository is initialized
if [ ! -d ".git" ]; then
    git init
    git branch -M main
fi

# Stage and commit current state
git add .
git commit -m "Snapshot: Locking state prior to split-test branching at $(date)"

# Tag the stable baseline
git tag "$VERSION_TAG"
echo "[+] Baseline preserved with tag: $VERSION_TAG"

# Create split-test target directories via git worktrees
echo "[+] Spawning variant repositories for split-testing..."

# Variant A: Focus on UI/UX or subtle frontend tweaks
git worktree add "$SPLIT_DIR_A" main
echo "[+] Variant A successfully created at: $SPLIT_DIR_A"

# Variant B: Focus on backend logic or auth alterations
git worktree add -b "variant-b-logic" "$SPLIT_DIR_B" main
echo "[+] Variant B successfully created at: $SPLIT_DIR_B"

echo "[+] All repositories successfully branched and ready for isolated split-testing!"
