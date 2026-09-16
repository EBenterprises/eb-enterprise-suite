#!/bin/bash
set -e

echo "Removing nested .git directories and invalid submodule pointers..."
find . -mindepth 2 -name ".git" -type d -prune -exec rm -rf {} +
rm -f .gitmodules

echo "Fixing problematic mongo directory index state..."
git rm --cached mongo 2>/dev/null || true
rm -rf mongo/.git 2>/dev/null || true

echo "Re-adding and staging entire clean project tree..."
git add -A

echo "Committing workspace snapshot..."
git commit -m "feat: flatten embedded git repositories and stabilize workspace index"

echo "Repository successfully stabilized."
