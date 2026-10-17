#!/usr/bin/env bash
set -euo pipefail

echo "=== Git Log (Last 30 commits with dates) ==="
git log -n 30 --oneline --date=local
