#!/data/data/com.termux/files/usr/bin/bash
set -e

FILE="api/domain-service.js"
BACKUP="$FILE.before-final-10b-fix"

cp "$FILE" "$BACKUP"

python - <<'PY'
from pathlib import Path

p = Path("api/domain-service.js")
s = p.read_text()

start = s.index("function updateOrderStatus(orderId, status) {")
end = s.index("\nfunction assignDriver(", start)

fn = s[start:end]

old = """    const current = order.status;
    lifecycle.assertOrderTransition(current, status);

    lifecycle.assertOrderTransition(order.status, status);

    const current = order.status;
    lifecycle.assertOrderTransition(current, status);
"""

new = """    const current = order.status;
    lifecycle.assertOrderTransition(current, status);
"""

if old not in fn:
    print("TARGET NOT FOUND")
    print(fn)
    raise SystemExit(2)

fn = fn.replace(old, new, 1)
p.write_text(s[:start] + fn + s[end:])
PY

clear

echo "=== REQUEST RUNNER® — STEP 10B FINAL FIX ==="
echo

node --check "$FILE"
echo "✓ SYNTAX"

echo
echo "[VERIFY]"
grep -nE 'const current = order.status|lifecycle.assertOrderTransition' "$FILE"

echo
echo "[STEP 10B]"
./STEP10B_WIRE_CANONICAL_LIFECYCLE.sh >/dev/null
echo "✓ STEP 10B"

rm -f "$BACKUP"

clear
echo "=== REQUEST RUNNER® ==="
echo
echo "✓ STEP 10B FIXED"
echo "✓ DOMAIN SYNTAX VALID"
echo "✓ LIFECYCLE WIRING VALID"
