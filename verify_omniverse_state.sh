#!/usr/bin/env bash

echo "=== 1. CHECKING CURRENT ACTIVE BRANCH & REPO STATE ==="
git branch --show-current
git log -1 --oneline

echo ""
echo "=== 2. VERIFYING KEY ECOSYSTEM DIRECTORIES ==="
for dir in sales-tracker secure_vault eb-enterprises-empire tapchat-monorepo mobile-app; do
    if [ -d "$dir" ]; then
        echo "[FOUND] $dir directory is intact."
    else
        echo "[NOTICE] $dir not found in root path."
    fi
done

echo ""
echo "=== 3. FINAL GIT WORKSPACE STATUS ==="
git status --short
