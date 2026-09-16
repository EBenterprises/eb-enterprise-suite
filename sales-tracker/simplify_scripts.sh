#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Script Simplification & Renaming
# ==============================================================================
set -e

echo "[+] Renaming scripts to remove 'update_' and simplify workspace..."

# Rename existing script files if they exist
[ -f "update_live_totals.sh" ] && mv update_live_totals.sh live_totals.sh
[ -f "update_styling.sh" ] && mv update_styling.sh styling.sh
[ -f "continue_operations.sh" ] && mv continue.sh 2>/dev/null || true
[ -f "export_deploy.sh" ] && mv export.sh 2>/dev/null || true
[ -f "verify_archive.sh" ] && mv verify.sh 2>/dev/null || true

echo "[+] Creating unified master control script: run.sh"
cat << 'ERUN' > run.sh
#!/bin/bash
set -e
echo "[+] Starting EB Sales Tracker..."
pkill -f "node server.js" || true
nohup node server.js > server.log 2>&1 &
echo "[+] Server running live on http://localhost:3000"
ERUN
chmod +x run.sh

echo "[+] Creating unified export script: deploy.sh"
cat << 'EDEP' > deploy.sh
#!/bin/bash
set -e
ARCHIVE_NAME="sales-tracker-$(date +%Y%m%d_%H%M%S).tar.gz"
echo "[+] Packaging application..."
tar -czf "$ARCHIVE_NAME" --exclude="node_modules" --exclude=".git" --exclude="*.tar.gz" .
echo "[+] Created archive: $ARCHIVE_NAME"
EDEP
chmod +x deploy.sh

echo "[+] Cleaning up redundant script files..."
rm -f update_live_totals.sh update_styling.sh continue_operations.sh export_deploy.sh verify_archive.sh

echo "[+] Simplification complete. Available commands:"
echo "    ./run.sh     - Start server"
echo "    ./deploy.sh  - Export deployment archive"
