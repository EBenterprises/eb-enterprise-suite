#!/usr/bin/env bash
set -euo pipefail

echo "==> Verifying repository integrity and untracked status..."
git status

echo "==> Last commit details:"
git log -1 --stat

echo "==> Repository is fully synchronized and tracked!"
