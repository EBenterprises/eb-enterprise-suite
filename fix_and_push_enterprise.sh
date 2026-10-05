#!/bin/bash

# ==============================================================================
# E&B ENTERPRISES - GIT REPOSITORY INITIALIZER & PRODUCTION PUSH FIXER
# Organization: EBenterprises
# Target Repository: eb-enterprise-suite
# ==============================================================================

set -e

echo "[*] Initializing/Configuring Git Repository credentials..."
git config user.name "Easton Bodeux"
git config user.email "eastonbodeuxenterprises@gmail.com"

echo "[*] Staging and committing all local enterprise files..."
git add -A
git commit -m "feat: Comprehensive enterprise suite production release v2.0" || echo "No new changes to commit."

echo "[*] Configuring remote origin for EBenterprises/eb-enterprise-suite..."
git remote remove origin 2>/dev/null || true
git remote add origin https://github.com/EBenterprises/eb-enterprise-suite.git

echo "[*] Preparing branch and setting up push..."
git branch -M main

echo "=========================================================================="
echo "REPOSITORY READY FOR GITHUB PUSH!"
echo "If your GitHub Personal Access Token is configured or SSH is active, run:"
echo "  git push -u origin main --force"
echo "=========================================================================="
