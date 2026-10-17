#!/usr/bin/env bash
echo "=== EB Enterprises® Sales Tracker Reboot Automation ==="

# 1. Stop any running instances of the server
echo "Stopping existing Node processes on port 51205..."
fuser -k 51205/tcp 2>/dev/null || true

# 2. Run update script if present
if [ -f "update.js" ]; then
    echo "Running incremental updates..."
    node update.js
fi

# 3. Synchronize with GitHub repository under EBenterprises organization
echo "Pushing updates to GitHub repository..."
git add .
git commit -m "chore: reboot and sync sales-tracker v1-v5 updates with reverse chronological sorting" || echo "No changes to commit."
git push origin main || echo "Git push skipped or failed."

# 4. Start server on designated port 51205
echo "Starting server on port 51205..."
PORT=51205 node server.js
