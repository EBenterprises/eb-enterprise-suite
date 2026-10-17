#!/usr/bin/env bash
set -euo pipefail

echo "=== Restoring stashed changes ==="
git stash pop || git stash apply

echo "=== Checking status of restored files ==="
git status
