#!/usr/bin/env bash
set -euo pipefail

echo "=== Removing stale git lock files ==="
rm -f .git/index.lock /data/data/com.termux/files/home/.git/index.lock 2>/dev/null || true

echo "=== Returning to main branch ==="
git checkout main || git checkout -f main

echo "=== Resolving conflict on fix_and_boot_cluster.sh by accepting stashed/working version ==="
git checkout --ours sales-tracker/fix_and_boot_cluster.sh 2>/dev/null || true
rm -f fix_and_boot_cluster.sh 2>/dev/null || true

echo "=== Applying stash cleanly now ==="
git stash pop || true

echo "=== Git status check ==="
git status
