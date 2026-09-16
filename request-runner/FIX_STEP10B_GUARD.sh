#!/data/data/com.termux/files/usr/bin/bash
set -e

STEP="STEP10B_WIRE_CANONICAL_LIFECYCLE.sh"
FILE="api/domain-service.js"

cp "$STEP" "$STEP.before-guard"
cp "$FILE" "$FILE.before-guard"

node <<'NODE'
const fs = require("fs");

const file = "STEP10B_WIRE_CANONICAL_LIFECYCLE.sh";
let s = fs.readFileSync(file, "utf8");

const re = /if \(s\.includes\(oldOrder\)\) \{\s*s = s\.replace\(oldOrder, neuOrder\);\s*\}/;

const replacement = `const orderStart = s.indexOf("function updateOrderStatus(orderId, status) {");
  const driverStart = s.indexOf("\\\\nfunction assignDriver(", orderStart);
  const orderFn = orderStart >= 0 && driverStart > orderStart
    ? s.slice(orderStart, driverStart)
    : "";

  if (s.includes(oldOrder) && !orderFn.includes("lifecycle.assertOrderTransition(current, status)")) {
    s = s.replace(oldOrder, neuOrder);
  }`;

if (!re.test(s)) {
  throw new Error("Could not locate the STEP10B order injection block");
}

s = s.replace(re, replacement);
fs.writeFileSync(file, s);
NODE

clear
echo "=== REQUEST RUNNER® — STEP 10B GUARD ==="
echo

echo "[1] SCRIPT SYNTAX"
bash -n "$STEP"
echo "✓"

echo
echo "[2] DOMAIN SYNTAX"
node --check "$FILE"
echo "✓"

echo
echo "[3] IDEMPOTENCY TEST"

./"$STEP" >/dev/null
node --check "$FILE"

./"$STEP" >/dev/null
node --check "$FILE"

echo "✓ RUN 1"
echo "✓ RUN 2"

echo
echo "[4] VERIFY"

COUNT=$(sed -n '/function updateOrderStatus/,/^function assignDriver/p' "$FILE" |
  grep -c 'const current = order.status' || true)

ASSERT=$(sed -n '/function updateOrderStatus/,/^function assignDriver/p' "$FILE" |
  grep -c 'lifecycle.assertOrderTransition(current, status)' || true)

echo "current declarations: $COUNT"
echo "lifecycle assertions: $ASSERT"

if [ "$COUNT" -ne 1 ] || [ "$ASSERT" -ne 1 ]; then
    echo
    echo "✗ IDEMPOTENCY FAILED"
    exit 1
fi

echo "✓ EXACTLY ONE OF EACH"

rm -f "$STEP.before-guard" "$FILE.before-guard"

clear
echo "=== REQUEST RUNNER® ==="
echo
echo "✓ STEP 10B FIXED"
echo "✓ IDEMPOTENT"
echo "✓ DOMAIN CLEAN"
echo "✓ TWO RUNS PASSED"
echo
echo "CHECKPOINT: 10"
