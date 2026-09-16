#!/usr/bin/env bash
set -euo pipefail

echo "==> Fetching local operations page endpoint..."
curl -s http://localhost:3000/operations || echo "Server might not be responding on port 3000. Checking process..."
ps aux | grep node
tail -n 30 server.log
