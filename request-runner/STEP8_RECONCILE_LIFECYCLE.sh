#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "=== EB PLATFORM® STEP 8 — RECONCILE LIFECYCLE ==="

BACKUP=".backups/pre-real-lifecycle-20260810-143832"
test -d "$BACKUP"

echo
echo "[CURRENT MODULE]"
find . -maxdepth 4 -type f \
  \( -iname '*lifecycle*' -o -iname '*transition*' \) \
  -not -path './node_modules/*' \
  -not -path './.next/*' \
  -not -path './.git/*' \
  -print 2>/dev/null

echo
echo "[DOMAIN TRANSITIONS]"
cat framework/domain/request.js 2>/dev/null || true
cat framework/domain/order.js 2>/dev/null || true

echo
echo "[CANONICAL RULE]"
echo "pending -> accepted -> assigned -> en_route -> arrived -> picked_up -> completed"

echo
echo "[API ASSIGNMENT]"
grep -n -A25 -B5 'requests/:id/assign' api/platform-api.js

echo
echo "[DOMAIN ASSIGNMENT]"
grep -n -A35 -B5 'function assignDriver' api/domain-service.js

echo
echo "[RESULT]"
echo "accepted -> assigned must be supported by the canonical lifecycle."

echo
echo "=== STEP 8 AUDIT COMPLETE — NO DATA MODIFIED ==="
