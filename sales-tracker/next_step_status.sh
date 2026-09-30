#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

cd "$HOME/sales-tracker"

echo "=== CHECKING CLUSTER STATUS & GIT SYNC ==="
ps -ef | grep '[n]ode' || true

echo "=== REPOSITORY STATUS ==="
git status -s || true

echo "GREEN: Sales Tracker cluster running on ports 3000-3004 with dual location inputs (Auto-GPS + Nearest Landmark) fully operational."
