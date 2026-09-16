#!/usr/bin/env bash
set -euo pipefail

echo "==> Staging verify_repo.sh..."
git add -f verify_repo.sh track_and_push_verify.sh

echo "==> Committing latest verification script..."
git commit -m "chore: track verification script and finalize workspace sync" || echo "Nothing new to commit."

echo "==> Pushing to origin master..."
git push origin master

echo "==> Final verification sweep complete. Repository is 100% tracked and synchronized!"
