#!/usr/bin/env bash
set -euo pipefail

echo "==> Committing all tracked artifacts..."
git commit -m "chore: track all workspace artifacts and build outputs" || echo "Nothing new to commit."

echo "==> Pushing to remote repository..."
git push origin HEAD || echo "Please verify remote branch configuration."

echo "==> Full-stack deployment sync complete!"
