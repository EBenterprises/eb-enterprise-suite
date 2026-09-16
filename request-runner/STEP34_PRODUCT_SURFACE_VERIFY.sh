#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "=== EB PLATFORM® STEP 34 — PRODUCT SURFACE VERIFY ==="

for path in /requests /orders /drivers /ops; do
  code=$(curl -s -o /dev/null -w "%{http_code}" "http://127.0.0.1:3000$path")
  echo "$path = HTTP $code"
  test "$code" = "200"
done

curl -fsS http://127.0.0.1:3000/api/health >/dev/null

echo "✓ product routes"
echo "✓ API healthy"
echo "✓ STEP 34 PASSED"
