#!/data/data/com.termux/files/usr/bin/bash
set -e

STEP="STEP10B_WIRE_CANONICAL_LIFECYCLE.sh"
FILE="api/domain-service.js"

cp "$STEP" "$STEP.pre-final-fix"
cp "$FILE" "$FILE.pre-final-fix"

node <<'NODE'
const fs = require("fs");

const file = "STEP10B_WIRE_CANONICAL_LIFECYCLE.sh";
let s = fs.readFileSync(file, "utf8");

const begin = s.indexOf('  const oldOrder = `');
const end = s.indexOf('\n\n  fs.writeFileSync(file, s);', begin);

if (begin < 0 || end < 0) {
  throw new Error("STEP10B order section boundaries not found");
}

const replacement = `  const oldOrder = \`return store.update("orders", orderId, {
        status
    });\`;

  const neuOrder = \`const current = order.status;
    lifecycle.assertOrderTransition(current, status);

    return store.update("orders", orderId, {
        status
    });\`;

  const orderStart = s.indexOf("function updateOrderStatus(orderId, status) {");
  const driverStart = s.indexOf("\\\\nfunction assignDriver(", orderStart);
  const orderFn = orderStart >= 0 && driverStart > orderStart
    ? s.slice(orderStart, driverStart)
    : "";

  if (s.includes(oldOrder) &&
      !orderFn.includes("lifecycle.assertOrderTransition(current, status)")) {
    s = s.replace(oldOrder, neuOrder);
  }`;

s = s.slice(0, begin) + replacement + s.slice(end);

fs.writeFileSync(file, s);
NODE

clear
echo "=== REQUEST RUNNER® — STEP 10B FINAL REPAIR ==="
echo

echo "[1] STEP SCRIPT"
bash -n "$STEP"
echo "✓"

echo
echo "[2] CURRENT DOMAIN"
node --check "$FILE"
echo "✓"

echo
echo "[3] IDEMPOTENCY"

./"$STEP" >/dev/null
node --check "$FILE"

./"$STEP" >/dev/null
node --check "$FILE"

echo "✓ RUN 1"
echo "✓ RUN 2"

COUNT=$(sed -n '/function updateOrderStatus/,/^function assignDriver/p' "$FILE" |
  grep -c 'const current = order.status' || true)

ASSERT=$(sed -n '/function updateOrderStatus/,/^function assignDriver/p' "$FILE" |
  grep -c 'lifecycle.assertOrderTransition(current, status)' || true)

echo
echo "current declarations: $COUNT"
echo "lifecycle assertions: $ASSERT"

test "$COUNT" -eq 1
test "$ASSERT" -eq 1

echo "✓ EXACTLY ONE DECLARATION"
echo "✓ EXACTLY ONE ASSERTION"

rm -f "$STEP.pre-final-fix" "$FILE.pre-final-fix"

clear
echo "=== REQUEST RUNNER® ==="
echo
echo "✓ STEP 10B FIXED"
echo "✓ IDEMPOTENT"
echo "✓ TWO CONSECUTIVE RUNS PASSED"
echo
echo "CHECKPOINT: 10"
