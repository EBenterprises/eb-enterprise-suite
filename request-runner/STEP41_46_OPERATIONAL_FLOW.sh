#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "=== EB PLATFORM® STEPS 41–46 — OPERATIONAL FLOW ==="

echo "[41] REQUEST API"
curl -fsS http://127.0.0.1:3000/api/requests >/dev/null
echo "✓"

echo "[42] ORDER API"
curl -fsS http://127.0.0.1:3000/api/orders >/dev/null
echo "✓"

echo "[43] CUSTOMER API"
curl -fsS http://127.0.0.1:3000/api/customers >/dev/null
echo "✓"

echo "[44] DRIVER API"
curl -fsS http://127.0.0.1:3000/api/drivers >/dev/null
echo "✓"

echo "[45] REALTIME"
curl -fsS http://127.0.0.1:3001/ >/dev/null
echo "✓"

echo "[46] FULL RUNTIME"
curl -fsS http://127.0.0.1:3000/api/health >/dev/null
node --check api/domain-service.js
node --check framework/lifecycle/canonical-lifecycle.js
node --check realtime-server.js
echo "✓"

echo
echo "=== STEPS 41–46 COMPLETE ==="
echo "✓ ALL PASSED"
echo "✓ NO DATA MODIFIED"
