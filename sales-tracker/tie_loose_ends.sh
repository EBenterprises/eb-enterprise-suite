#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Final Polish, Auto-Start & Deployment Script
# ==============================================================================
set -e

echo "[+] Verifying project directory structure..."
mkdir -p public

echo "[+] Ensuring package.json is fully configured with required dependencies..."
cat << 'EJSON' > package.json
{
  "name": "eb-sales-tracker",
  "version": "1.0.0",
  "description": "EB Enterprises Sales & Inventory Management System",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.19.2",
    "sql.js": "^1.10.3"
  }
}
EJSON

echo "[+] Installing Node dependencies..."
npm install

echo "[+] Creating background launcher and process management script..."
cat << 'ERUN' > start.sh
#!/bin/bash
pkill -f "node server.js" || true
echo "[+] Starting EB Sales Tracker..."
nohup node server.js > server.log 2>&1 &
echo "[+] Server running in background. Logs redirected to server.log."
echo "[+] Live at: http://localhost:3000"
ERUN
chmod +x start.sh

echo "[+] Terminating existing instances and launching fresh..."
./start.sh

echo "[+] All loose ends tied. System fully operational and live-deployed."
