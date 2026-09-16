#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "=== EB PLATFORM® STEPS 47–54 — PLATFORM CONTRACT ==="

echo "[47] REQUEST SURFACE"
test -f app/requests/page.js
echo "✓"

echo "[48] ORDER SURFACE"
test -f app/orders/page.js
echo "✓"

echo "[49] DRIVER SURFACE"
test -f app/drivers/page.js
echo "✓"

echo "[50] OPERATIONS SURFACE"
test -f app/ops/page.js
echo "✓"

echo "[51] AUTHORIZATION"
node --check framework/security/authorization.js
echo "✓"

echo "[52] SESSION"
node --check framework/security/session.js
echo "✓"

echo "[53] LIFECYCLE"
node --check framework/lifecycle/canonical-lifecycle.js
echo "✓"

echo "[54] COMPLETE RUNTIME"
node --check api/domain-service.js
node --check api/platform-api.js
node --check realtime-server.js
curl -fsS http://127.0.0.1:3000/api/health >/dev/null
curl -fsS http://127.0.0.1:3001/ >/dev/null
echo "✓"

echo
echo "=== STEPS 47–54 COMPLETE ==="
echo "✓ ALL PASSED"
echo "✓ NO DATA MODIFIED"
