#!/usr/bin/env bash

echo "=== [1] Local Folders with Node / App Files ==="
find $HOME -maxdepth 3 -type f \( -name "package.json" -o -name "server*.js" -o -name "transactions.json" \) 2>/dev/null | while read -r file; do
    echo "Found match: $file"
done

echo ""
echo "=== [2] Checking Remote Connection to GitHub ==="
ssh -T git@github.com 2>&1 | head -n 2 || true

echo ""
echo "=== [3] Checking Local Git Stashes in $HOME ==="
cd $HOME && git stash list 2>/dev/null || true

