#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "=== EB PLATFORM® STEP 10B — WIRE LIFECYCLE ==="

BACKUP=".backups/pre-real-lifecycle-20260810-143832"
test -d "$BACKUP"

cp -f api/domain-service.js \
  "$BACKUP/domain-service.js.step10"

node <<'NODE'
const fs = require("fs");

const file = "api/domain-service.js";
let s = fs.readFileSync(file, "utf8");

const lifecycleImport =
  'const lifecycle = require("../framework/lifecycle/canonical-lifecycle");';

if (!s.includes("canonical-lifecycle")) {
  const crypto = 'const crypto = require("crypto");';

  if (!s.includes(crypto)) {
    throw new Error("crypto import not found");
  }

  s = s.replace(
    crypto,
    crypto + "\n" + lifecycleImport
  );
}

function isolateFunction(source, startMarker, endMarker) {
  const start = source.indexOf(startMarker);
  const end = source.indexOf(endMarker, start);

  if (start < 0 || end < 0) {
    throw new Error(`Function boundary not found: ${startMarker}`);
  }

  return {
    start,
    end,
    body: source.slice(start, end)
  };
}

/* REQUEST LIFECYCLE */

{
  const part = isolateFunction(
    s,
    "function updateRequestStatus(",
    "\nfunction updateOrderStatus("
  );

  if (!part.body.includes("lifecycle.assertRequestTransition")) {
    const marker = `    return store.update("requests", requestId, {
        status
    });`;

    if (!part.body.includes(marker)) {
      throw new Error("Request update location not found");
    }

    const replacement = `    const current = request.status;
    lifecycle.assertRequestTransition(current, status);

${marker}`;

    const body = part.body.replace(marker, replacement);

    s = s.slice(0, part.start) + body + s.slice(part.end);
  }
}

/* ORDER LIFECYCLE */

{
  const part = isolateFunction(
    s,
    "function updateOrderStatus(",
    "\nfunction assignDriver("
  );

  if (!part.body.includes("lifecycle.assertOrderTransition")) {
    const marker = `    return store.update("orders", orderId, {
        status
    });`;

    if (!part.body.includes(marker)) {
      throw new Error("Order update location not found");
    }

    const replacement = `    const current = order.status;
    lifecycle.assertOrderTransition(current, status);

${marker}`;

    const body = part.body.replace(marker, replacement);

    s = s.slice(0, part.start) + body + s.slice(part.end);
  }
}

fs.writeFileSync(file, s);
NODE

node --check api/domain-service.js
node --check framework/lifecycle/canonical-lifecycle.js

echo "✓ DOMAIN WIRED"
echo "✓ SYNTAX PASS"

echo
echo "=== HEALTH ==="

if [ -f api/health.js ]; then
  node --check api/health.js
fi

echo "✓ HEALTH CHECK"

echo
echo "=== STEP 10B COMPLETE ==="
