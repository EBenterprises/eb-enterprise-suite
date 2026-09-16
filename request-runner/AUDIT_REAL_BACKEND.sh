#!/data/data/com.termux/files/usr/bin/bash
set -u

echo "=============================================================="
echo " EB PLATFORM® — REAL BACKEND CONTRACT AUDIT"
echo "=============================================================="

echo
echo "=== APPLICATION SERVICE ==="
sed -n '1,260p' framework/application-service.js 2>/dev/null || \
sed -n '1,260p' application-service.js 2>/dev/null || true

echo
echo "=== STORE ==="
sed -n '1,300p' api/store.js 2>/dev/null || true

echo
echo "=== DOMAIN SERVICE ==="
sed -n '1,320p' api/domain-service.js 2>/dev/null || true

echo
echo "=== PLATFORM API ==="
sed -n '1,320p' api/platform-api.js 2>/dev/null || true

echo
echo "=== ENTITY ==="
sed -n '1,240p' framework/domain/entity.js 2>/dev/null || true

echo
echo "=== REPOSITORY FILES ==="
find framework api -type f 2>/dev/null | sort | \
grep -Ei 'repository|service|store|request|order|driver|dispatch'

echo
echo "=== REQUEST API POST TEST CONTRACT ==="
curl -sS -X POST \
  -H 'Content-Type: application/json' \
  http://127.0.0.1:3000/api/requests \
  -d '{
    "customerId":"audit-customer",
    "pickup":"Audit Pickup",
    "destination":"Audit Destination"
  }' || true

echo
echo
echo "=== REQUEST COLLECTION AFTER POST ==="
curl -sS http://127.0.0.1:3000/api/requests || true

echo
echo
echo "=== CURRENT DATA FILES ==="
find data -maxdepth 2 -type f -printf '%p %s bytes\n' 2>/dev/null | sort

echo
echo
echo "=== SERVER PROCESS ==="
ps -ef 2>/dev/null | grep -E 'next|server.js|request-runner' | grep -v grep || true

echo
echo "=============================================================="
echo " AUDIT COMPLETE"
echo "=============================================================="
