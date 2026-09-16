#!/bin/bash
# ==============================================================================
# PROPRIETARY ASSET: EB Enterprises - Production Deployment & Verification Script
# ==============================================================================
set -e

echo "[+] Verifying project directory structure..."
mkdir -p public

echo "[+] Ensuring package.json configuration..."
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

echo "[+] Installing dependencies..."
npm install --production

echo "[+] Creating production runner: run.sh"
cat << 'ERUN' > run.sh
#!/bin/bash
pkill -f "node server.js" || true
echo "[+] Starting EB Sales Tracker..."
nohup node server.js > server.log 2>&1 &
echo "[+] Server running in background. Logs redirected to server.log."
echo "[+] Live at: http://localhost:3000"
ERUN
chmod +x run.sh

echo "[+] Creating status health check script: status.sh"
cat << 'ESTAT' > status.sh
#!/bin/bash
if pgrep -f "node server.js" > /dev/null; then
    PID=$(pgrep -f "node server.js")
    echo "[+] Server Status: RUNNING (PID: $PID)"
    echo "--- Last 5 Log Entries ---"
    tail -n 5 server.log
    echo "--------------------------"
    echo "--- Endpoint Health Check ---"
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/sales || echo "Failed")
    echo "[+] API /api/sales responded with status: $STATUS"
else
    echo "[!] Server Status: STOPPED"
fi
ESTAT
chmod +x status.sh

echo "[+] Creating deployment archive script: deploy.sh"
cat << 'EDEP' > deploy.sh
#!/bin/bash
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
ARCHIVE="eb-sales-tracker-deployment-$TIMESTAMP.tar.gz"
echo "[+] Packaging application state..."
tar -czf "$ARCHIVE" --exclude="node_modules" --exclude="*.tar.gz" .
echo "[+] Archive created: $ARCHIVE"
EDEP
chmod +x deploy.sh

echo "[+] Launching live server..."
./run.sh

echo "[+] Executing system health check..."
sleep 1
./status.sh

echo "[+] Full-stack deployment script execution complete."
