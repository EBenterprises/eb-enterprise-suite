#!/usr/bin/env bash
set -uo pipefail

echo "=== Checking Git Stash List ==="
git stash list

echo "=== Checking Git Branches ==="
git branch -a

echo "=== Checking git status ==="
git status
