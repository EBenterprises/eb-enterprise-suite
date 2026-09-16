#!/data/data/com.termux/files/usr/bin/bash
set -e

clear
echo "=== EB PLATFORM® STEP 13B — LOCATE 404 ==="

for p in \
  /api/health \
  /api/customers \
  /api/requests \
  /api/orders \
  /api/customers/test \
  /api/requests/test \
  /api/orders/test
do
  code=$(curl -s -o /dev/null -w "%{http_code}" "http://127.0.0.1:3000$p")
  printf '%-25s %s\n' "$p" "$code"
done

echo
echo "=== ROUTES ==="
find app/api -type f -name 'route.js' -print | sort

echo
echo "=== STEP 13B COMPLETE ==="
