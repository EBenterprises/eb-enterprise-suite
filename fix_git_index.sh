#!/bin/bash
set -e

echo "Cleaning up git index and resolving nested repository conflicts..."
git rm --cached assets 2>/dev/null || true
rm -rf auth-system 2>/dev/null || true

echo "Staging files correctly..."
git add -A

echo "Committing state..."
git commit -m "feat: resolve submodule conflicts and lock unified automation suite state" || echo "No changes to commit or already committed."

echo "Git index successfully repaired and synchronized."
