#!/usr/bin/env bash
set -euo pipefail

WORKSPACE_DIR="${HOME}/termux_workspace"
cd "$WORKSPACE_DIR"

echo "=== Initializing Executive Spectrum Launchpad & Final Verification ==="

# 1. Run full validation
python3 bootstrap_verify.py
python3 self_diagnostics.py
python3 ecosystem_summary.py

# 2. Final git sync check
git add .
if ! git diff --cached --quiet; then
    git commit -m "Launchpad finalization: Complete ecosystem verified and synchronized $(date '+%Y-%m-%d %H:%M:%S')"
    git push origin main || true
fi

echo "=========================================================="
echo "      EXECUTIVE SPECTRUM ECOSYSTEM FULLY OPERATIONAL      "
echo "=========================================================="
echo "Available Global Commands & Utilities:"
echo "  - workspace           : Launch master orchestrator & sync suite"
echo "  - dashboard           : Launch interactive Terminal UI (TUI)"
echo "  - snippets            : Manage SQLite code snippet storage"
echo "  - workspace-archive   : Generate compressed repository archive"
echo "=========================================================="
