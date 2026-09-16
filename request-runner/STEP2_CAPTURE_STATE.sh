#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "=============================================================="
echo " EB PLATFORM® — STEP 2 STATE CAPTURE"
echo "=============================================================="

echo
echo "=== HEALTH ==="
curl -fsS http://127.0.0.1:3000/api/health
echo

echo
echo "=== CUSTOMERS ==="
curl -fsS http://127.0.0.1:3000/api/customers
echo

echo
echo "=== REQUESTS ==="
curl -fsS http://127.0.0.1:3000/api/requests
echo

echo
echo "=== ORDERS ==="
if [ -f data/orders.json ]; then
    cat data/orders.json
else
    echo "No data/orders.json"
fi

echo
echo
echo "=== LISTENING PORTS ==="
ss -ltn 2>/dev/null | grep -E ':3000|:3001' || true

echo
echo "=== GIT STATUS ==="
git status --short 2>/dev/null || true

echo
echo "=============================================================="
echo " STATE CAPTURE COMPLETE"
echo "=============================================================="
