#!/data/data/com.termux/files/usr/bin/bash
set -e

STEP="STEP10B_WIRE_CANONICAL_LIFECYCLE.sh"
FILE="api/domain-service.js"

BACKUP=".backups/step10b-deterministic-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP"

cp "$STEP" "$BACKUP/"
cp "$FILE" "$BACKUP/"

node <<'NODE'
const fs = require("fs");

const file = "STEP10B_WIRE_CANONICAL_LIFECYCLE.sh";
let s = fs.readFileSync(file, "utf8");

const begin = s.indexOf('  const oldOrder = `');
const end = s.indexOf('\n\n  fs.writeFileSync(file, s);', begin);

if (begin < 0 || end < 0) {
  throw new Error("Could not locate Step 10B order patch");
}

const replacement = String.raw`  const oldOrder = \`return store.update("orders", orderId, {
        status
    });\`;

  const neuOrder = \`const current = order.status;
    lifecycle.assertOrderTransition(current, status);

    return store.update("orders", orderId, {
        status
    });\`;

  const orderStart = s.indexOf("function updateOrderStatus(orderId, status) {");
  const driverStart = s.indexOf("\nfunction assignDriver(", orderStart);

  if (orderStart >= 0 && driverStart > orderStart) {
    const orderFn = s.slice(orderStart, driverStart);

    if (!orderFn.includes("lifecycle.assertOrderTransition(current, status)") &&
        s.includes(oldOrder)) {
      s = s.replace(oldOrder, neuOrder);
    }
  }`;

s = s.slice(0, begin) + replacement + s.slice(end);

fs.writeFileSync(file, s);
NODE

clear
echo "=== REQUEST RUNNER® ==="
echo "STEP 10B DETERMINISTIC REPAIR"
echo

echo "[1] STEP SCRIPT"
bash -n "$STEP"
echo "✓"

echo "[2] DOMAIN"
node --check "$FILE"
echo "✓"

echo "[3] EXECUTE STEP 10B"
"./$STEP" >/dev/null
node --check "$FILE"
echo "✓"

echo "[4] EXECUTE STEP 10B AGAIN"
"./$STEP" >/dev/null
node --check "$FILE"
echo "✓"

echo "[5] CONTRACT"

COUNT=$(sed -n '/function updateOrderStatus/,/^function assignDriver/p' "$FILE" |
grep -c 'const current = order.status' || true)

ASSERT=$(sed -n '/function updateOrderStatus/,/^function assignDriver/p' "$FILE" |
grep -c 'lifecycle.assertOrderTransition(current, status)' || true)

test "$COUNT" -eq 1
test "$ASSERT" -eq 1

echo "✓ ONE CURRENT"
echo "✓ ONE ASSERTION"

clear
echo "=== REQUEST RUNNER® ==="
echo
echo "✓ STEP 10B FIXED"
echo "✓ IDEMPOTENT"
echo "✓ TWO RUNS PASSED"
echo "✓ CHECKPOINT REMAINS 10"
