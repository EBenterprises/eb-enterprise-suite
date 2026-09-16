#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "=============================================================="
echo " EB PLATFORM® — STEP 3 LIFECYCLE DIAGNOSTIC"
echo "=============================================================="

echo
echo "=== APPLICATION SERVICE ==="
sed -n '1,260p' framework/application-service.js 2>/dev/null || true

echo
echo "=== REQUEST ROUTES ==="
find app/api/requests -type f -maxdepth 3 -print -exec sh -c 'echo "--- $1"; cat "$1"' _ {} \;

echo
echo "=== ORDER ROUTES ==="
find app/api/orders -type f -maxdepth 3 -print -exec sh -c 'echo "--- $1"; cat "$1"' _ {} \;

echo
echo "=== DOMAIN SERVICES ==="
sed -n '1,320p' api/domain-service.js 2>/dev/null || true

echo
echo "=== PLATFORM API ==="
sed -n '1,360p' api/platform-api.js 2>/dev/null || true

echo
echo "=== ROUTER ==="
sed -n '1,320p' framework/api/router.js 2>/dev/null || true

echo
echo "=== SERVER LIFECYCLE REFERENCES ==="
grep -RInE \
'order:create|order:update|requests|orders|accept|accepted|transition|status' \
app api framework server.js apps \
--exclude-dir=node_modules \
--exclude-dir=.next \
--exclude-dir=.git \
2>/dev/null | head -400 || true

echo
echo "=== EXISTING DATA ==="
echo "Customers:"
curl -fsS http://127.0.0.1:3000/api/customers
echo
echo
echo "Requests:"
curl -fsS http://127.0.0.1:3000/api/requests
echo
echo
echo "Orders:"
curl -fsS http://127.0.0.1:3000/api/orders
echo

echo
echo "=============================================================="
echo " DIAGNOSTIC COMPLETE — NO DATA MODIFIED"
echo "=============================================================="
