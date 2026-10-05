#!/usr/bin/env bash
set -uo pipefail

echo "=== Git Stash List ==="
git stash list

echo -e "\n=== Checking Stash Content (if any) ==="
if git stash list | grep -q "stash@{0}"; then
    git stash show -p stash@{0} | head -n 50
fi

echo -e "\n=== Searching all commits for '1.75g' or 'map' ==="
git log --all -S "1.75g" --oneline
git log --all -S "map" --oneline -n 10
