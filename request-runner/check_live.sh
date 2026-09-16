#!/usr/bin/env bash
set -euo pipefail

echo "==> Verifying live /ops endpoint on port 3000..."
curl -sI http://localhost:3000/ops

echo "==> Checking process status..."
ps aux | grep node

echo "==> Live at http://localhost:3000/ops"
