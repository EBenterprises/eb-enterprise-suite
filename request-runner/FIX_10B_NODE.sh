#!/data/data/com.termux/files/usr/bin/bash
set -e

FILE="api/domain-service.js"
BACKUP="$FILE.before-node-10b-fix"

cp "$FILE" "$BACKUP"

node <<'NODE'
const fs = require("fs");

const file = "api/domain-service.js";
let source = fs.readFileSync(file, "utf8");

const startMarker = "function updateOrderStatus(orderId, status) {";
const endMarker = "\nfunction assignDriver(";

const start = source.indexOf(startMarker);
const end = source.indexOf(endMarker, start);

if (start < 0 || end < 0) {
    throw new Error("Could not locate updateOrderStatus()");
}

const before = source.slice(0, start);
const after = source.slice(end);
let fn = source.slice(start, end);

const duplicate = `    const current = order.status;
    lifecycle.assertOrderTransition(current, status);

    lifecycle.assertOrderTransition(order.status, status);

    const current = order.status;
    lifecycle.assertOrderTransition(current, status);
`;

const clean = `    const current = order.status;
    lifecycle.assertOrderTransition(current, status);
`;

if (!fn.includes(duplicate)) {
    throw new Error("Expected duplicate lifecycle block was not found. NO CHANGES MADE.");
}

fn = fn.replace(duplicate, clean);

fs.writeFileSync(file, before + fn + after);
NODE

clear

echo "=== REQUEST RUNNER® — STEP 10B REPAIR ==="
echo

node --check "$FILE"
echo "✓ DOMAIN SYNTAX"

echo
echo "[VERIFY]"
COUNT=$(grep -cE '^[[:space:]]*const current = order\.status;' "$FILE" || true)
echo "order current declarations: $COUNT"

if [ "$COUNT" -ne 1 ]; then
    echo "✗ EXPECTED EXACTLY 1 ORDER CURRENT DECLARATION"
    exit 1
fi

echo "✓ DECLARATION CLEAN"

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
