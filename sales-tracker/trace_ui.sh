#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - UI Revision History & Diff Inspector
# ==============================================================================
echo "[+] Inspecting command history and git diffs (if available)..."

if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo "[+] Git repository detected. Checking recent modifications to index.html..."
    git log -p -n 3 -- "**/index.html" || true
else
    echo "[+] Checking current index.html structures across generated scripts..."
    grep -n "Executive Spectrum" launch_sales_tracker.sh launch_multiversion.sh || true
fi
