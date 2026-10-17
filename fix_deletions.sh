#!/usr/bin/env bash

echo "=== 1. UNSTAGING ALL DELETIONS & CHANGES ==="
git reset HEAD .

echo "=== 2. RESTORING ALL DELETED TRACKED FILES FROM HEAD ==="
git checkout HEAD -- .

echo "=== 3. RECOVERING ALL MISSING FILES FROM LATEST STATE (93c6453) ==="
git checkout 93c6453 -- .

echo "=== 4. STAGING ALL RECOVERED ASSETS SAFELY ==="
git add .

echo "=== 5. CHECKING STATUS (NO DELETIONS REMAINING) ==="
git status --short | grep -E "^D|^ D" || echo "Zero deleted files! Everything is restored."
