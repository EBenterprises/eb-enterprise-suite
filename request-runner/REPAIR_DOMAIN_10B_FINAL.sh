#!/data/data/com.termux/files/usr/bin/bash
set -e

FILE="api/domain-service.js"
BACKUP=".backups/domain-10b-final-$(date +%Y%m%d-%H%M%S)"

mkdir -p "$BACKUP"
cp "$FILE" "$BACKUP/domain-service.js"

node <<'NODE'
const fs = require("fs");

const file = "api/domain-service.js";
let s = fs.readFileSync(file, "utf8");

const start = s.indexOf("function updateOrderStatus(");
const end = s.indexOf("\nfunction assignDriver(", start);

if (start < 0 || end < 0) {
  throw new Error("updateOrderStatus boundaries not found");
}

let fn = s.slice(start, end);

const block =
`    const current = order.status;
    lifecycle.assertOrderTransition(current, status);

`;

const first = fn.indexOf(block);

if (first < 0) {
  throw new Error("order lifecycle block not found");
}

const before = fn.slice(0, first + block.length);
let after = fn.slice(first + block.length);

while (after.includes(block)) {
  after = after.replace(block, "");
}

fn = before + after;

s = s.slice(0, start) + fn + s.slice(end);

fs.writeFileSync(file, s);
NODE

echo "=== REQUEST RUNNER® — DOMAIN 10B CLEAN ==="
echo

echo "[1] SYNTAX"
node --check "$FILE"
echo "✓"

echo
echo "[2] VERIFY"

COUNT=$(sed -n '/function updateOrderStatus/,/^function assignDriver/p' "$FILE" |
  grep -c 'const current = order.status' || true)

ASSERT=$(sed -n '/function updateOrderStatus/,/^function assignDriver/p' "$FILE" |
  grep -c 'lifecycle.assertOrderTransition(current, status)' || true)

echo "current declarations: $COUNT"
echo "lifecycle assertions: $ASSERT"

test "$COUNT" -eq 1
test "$ASSERT" -eq 1

echo "✓ ONE DECLARATION"
echo "✓ ONE ASSERTION"

echo
echo "[3] STEP 11"

if [ -f ./STEP11_LIFECYCLE_VERIFY.sh ]; then
  bash ./STEP11_LIFECYCLE_VERIFY.sh
else
  echo "STEP11_LIFECYCLE_VERIFY.sh not found"
  exit 2
fi

clear
echo "=== REQUEST RUNNER® ==="
echo
echo "✓ DOMAIN CLEAN"
echo "✓ STEP 11 PASSED"
