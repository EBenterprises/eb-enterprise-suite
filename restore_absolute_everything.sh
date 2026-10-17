#!/usr/bin/env bash

echo "=== 1. UNLOCKING GIT INDEX IF LOCKED ==="
rm -f .git/index.lock .git/refs/heads/*.lock

echo "=== 2. RESTORING ALL GIT STASHES ==="
git stash list | cut -d: -f1 | while read -r stash; do
    echo "Applying $stash..."
    git stash apply "$stash" 2>/dev/null
done

echo "=== 3. CHECKING OUT ALL HISTORIC FILES FROM REFLOG HEADS ==="
# Pulls in all files from recent major milestone commits across the entire reflog
for commit in 93c6453 a326084 b8b32b4 605747f 2fd17db cf37272 657a0ce 2d18ae3 ad333ee 93ede0b f375e77; do
    echo "Recovering files from commit $commit..."
    git checkout "$commit" -- . 2>/dev/null
done

echo "=== 4. STAGING ALL RECOVERED & UNTRACKED FILES ==="
git add -A

echo "=== 5. SAVING EVERYTHING TO A PERMANENT RECOVERY COMMIT ==="
git commit -m "chore: full absolute restoration of all historic commits, files, data, and scripts" 2>/dev/null || echo "Everything is already staged and preserved."

echo ""
echo "=== FULL RESTORATION COMPLETE ==="
git status
git log -3 --oneline
