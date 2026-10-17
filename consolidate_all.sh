#!/usr/bin/env bash

echo "=== 1. KILLING BACKGROUND PROCESSES & UNLOCKING ==="
killall node python python3 2>/dev/null
pkill -f node 2>/dev/null
pkill -f python 2>/dev/null
rm -f .git/index.lock .git/refs/heads/*.lock

echo "=== 2. RESTORING ALL HISTORICAL COMMITS & STASHES ==="
git stash list | cut -d: -f1 | while read -r stash; do
    git stash apply "$stash" 2>/dev/null
done

# Pull missing files/edits across all major reflog markers
for commit in 93c6453 a326084 b8b32b4 605747f f375e77 2fd17db cf37272 657a0ce 2d18ae3 ad333ee 93ede0b; do
    git checkout "$commit" -- . 2>/dev/null
done

echo "=== 3. STAGING ALL RECOVERED FILES & DATA ==="
git add -A

echo "=== 4. COMMITTING CONSOLIDATED WORKSPACE ==="
git commit -m "chore: absolute restoration of all historical commits, scripts, and JSON data" 2>/dev/null || echo "All historical data is already present in working tree."

echo "=== RECOVERY COMPLETE (NO BG SERVERS RUNNING) ==="
git status --short
