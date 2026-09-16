#!/bin/bash
set -e

echo "[+] Packaging current application state as v1..."

# Create releases directory structure
mkdir -p releases/v1

# Snapshot current application files into releases/v1/
cp -r server.js public package.json run.sh releases/v1/ 2>/dev/null || true
if [ -f "sales.sqlite" ]; then
    cp sales.sqlite releases/v1/
fi

# Initialize git repository if needed, commit, and tag as v1
if [ ! -d ".git" ]; then
    git init
    git add .
    git commit -m "EB Sales Tracker v1.0 Release - Executive Spectrum Edition"
else
    git add .
    git commit -m "EB Sales Tracker v1.0 Snapshot" || echo "[i] No new changes to commit."
fi

# Create or update git tag v1
if git rev-parse "v1" >/dev/null 2>&1; then
    git tag -d "v1" >/dev/null 2>&1 || true
fi
git tag -a "v1" -m "EB Sales Tracker Version 1.0"

echo "[+] v1 Release successfully snapshotted to releases/v1/ and tagged as v1 in Git."
