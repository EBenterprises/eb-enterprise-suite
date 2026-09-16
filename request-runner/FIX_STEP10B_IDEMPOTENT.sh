#!/data/data/com.termux/files/usr/bin/bash
set -e

STEP="STEP10B_WIRE_CANONICAL_LIFECYCLE.sh"
FILE="api/domain-service.js"

cp "$STEP" "$STEP.before-idempotency"
cp "$FILE" "$FILE.before-idempotency"

node <<'NODE'
const fs = require("fs");

const file = "STEP10B_WIRE_CANONICAL_LIFECYCLE.sh";
let s = fs.readFileSync(file, "utf8");

const old = `  if (s.includes(oldOrder)) {
    s = s.replace(oldOrder, neuOrder);
  }`;

const neu = `  const orderStart = s.indexOf("function updateOrderStatus(orderId, status) {");
  const driverStart = s.indexOf("\\nfunction assignDriver(", orderStart);
  const orderFn = orderStart >= 0 && driverStart > orderStart
    ? s.slice(orderStart, driverStart)
    : "";

  if (s.includes(oldOrder) && !orderFn.includes("lifecycle.assertOrderTransition")) {
    s = s.replace(oldOrder, neuOrder);
  }`;

if (!s.includes(old)) {
  throw new Error("STEP10B order patch condition not found");
}

s = s.replace(old, neu);
fs.writeFileSync(file, s);
NODE

clear
echo "=== REQUEST RUNNER® — STEP 10B IDEMPOTENCY ==="
echo

echo "[1] STEP SCRIPT"
bash -n "$STEP"
echo "✓"

echo
echo "[2] CLEAN DOMAIN"

node <<'NODE'
const fs = require("fs");

const file = "api/domain-service.js";
let s = fs.readFileSync(file, "utf8");

const start = s.indexOf("function updateOrderStatus(orderId, status) {");
const end = s.indexOf("\nfunction assignDriver(", start);

if (start < 0 || end < 0) {
  throw new Error("updateOrderStatus boundaries not found");
}

const fn = s.slice(start, end);

const marker =
`    const current = order.status;
    lifecycle.assertOrderTransition(current, status);

`;

if (!fn.includes(marker)) {
  throw new Error("Canonical order lifecycle block not found");
}

const prefix = fn.slice(0, fn.indexOf(marker) + marker.length);
const suffix = fn.slice(fn.indexOf(marker) + marker.length);

const cleanedSuffix = suffix.replace(
  /    const current = order\.status;\n    lifecycle\.assertOrderTransition\(current, status\);\n\n/g,
  ""
);

fs.writeFileSync(
  file,
  s.slice(0, start) + prefix + cleanedSuffix + s.slice(end)
);
NODE

node --check "$FILE"
echo "✓ DOMAIN CLEAN"

echo
echo "[3] RUN STEP 10B TWICE"

./"$STEP" >/dev/null
node --check "$FILE"

./"$STEP" >/dev/null
node --check "$FILE"

echo "✓ RUN 1"
echo "✓ RUN 2"

echo
echo "[4] VERIFY SINGLE ORDER TRANSITION"

COUNT=$(sed -n '/function updateOrderStatus/,/^function assignDriver/p' "$FILE" |
  grep -c 'const current = order.status' || true)

if [ "$COUNT" -ne 1 ]; then
    echo "✗ FAILED — FOUND $COUNT ORDER CURRENT DECLARATIONS"
    exit 1
fi

COUNT2=$(sed -n '/function updateOrderStatus/,/^function assignDriver/p' "$FILE" |
  grep -c 'lifecycle.assertOrderTransition(current, status)' || true)

if [ "$COUNT2" -ne 1 ]; then
    echo "✗ FAILED — FOUND $COUNT2 ORDER LIFECYCLE ASSERTIONS"
    exit 1
fi

echo "✓ ONE DECLARATION"
echo "✓ ONE ASSERTION"

rm -f "$FILE.before-idempotency"
rm -f "$STEP.before-idempotency"

clear
echo "=== REQUEST RUNNER® ==="
echo
echo "✓ STEP 10B IS IDEMPOTENT"
echo "✓ DOMAIN CLEAN"
echo "✓ TWO CONSECUTIVE RUNS PASSED"
echo
echo "CHECKPOINT REMAINS: 10"
echo "READY FOR STEP 11"
