#!/usr/bin/env bash
set -euo pipefail

echo "=== Searching for all server.js files across the repository ==="
find . -name "server.js" -not -path "*/node_modules/*"

echo "=== Searching for all index.html files across the repository ==="
find . -name "index.html" -not -path "*/node_modules/*"
