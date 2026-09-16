#!/bin/bash

echo "[+] Verifying remote sync status for all targets..."

if [ ! -d ".git" ]; then
    echo "[-] Error: No local git repository found."
    exit 1
fi

echo ""
echo "=== Configured Remotes ==="
git remote -v

echo ""
echo "=== Fetching Status from Remotes ==="
git fetch --all --tags

echo ""
echo "=== Branch Tracking & Health Check ==="
for remote in $(git remote); do
    echo "Checking remote: $remote"
    git status -u no | grep "Your branch" || true
    git rev-parse "$remote/main" 2>/dev/null && echo "[$remote] main branch verified." || echo "[$remote] main branch not found or unreachable."
done

echo ""
echo "[+] Verification complete. Review the output above to confirm successful push and sync state."
