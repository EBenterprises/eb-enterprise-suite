#!/usr/bin/env bash
set -euo pipefail

echo "==> Staging remaining untracked helper scripts..."
git add -f commit_push.sh status_report.sh sync_remaining.sh

echo "==> Committing updates..."
git commit -m "chore: track helper scripts and lock down complete workspace tracking" || echo "Nothing new to commit."

echo "==> Pushing to origin master..."
git push origin master

echo "==> Complete workspace successfully tracked and synchronized!"
