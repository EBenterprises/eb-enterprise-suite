#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

echo "=============================================================="
echo " EB PLATFORM® — REPAIR + VERIFY"
echo "=============================================================="

echo
echo "[1] Inspect EventBus API"
echo "--------------------------------------------------------------"

EVENT_FILE="$ROOT/framework/core/events/event-bus.js"

if [ ! -f "$EVENT_FILE" ]; then
    echo "✗ Missing EventBus: $EVENT_FILE"
    exit 1
fi

cat "$EVENT_FILE"

echo
echo "[2] Normalize EventBus compatibility"
echo "--------------------------------------------------------------"

cp "$EVENT_FILE" "$EVENT_FILE.bak.$(date +%Y%m%d%H%M%S)"

node <<'NODE'
const fs = require("fs");

const file = "framework/core/events/event-bus.js";
let src = fs.readFileSync(file, "utf8");

if (!src.includes("subscribe(")) {
  const classMatch = src.match(/class\s+EventBus\s*\{/);

  if (!classMatch) {
    console.error("Unable to locate EventBus class");
    process.exit(1);
  }

  const insertion = `
  subscribe(event, handler) {
    if (typeof handler !== "function") {
      throw new TypeError("EventBus.subscribe requires a function");
    }

    if (typeof this.on === "function") {
      return this.on(event, handler);
    }

    if (!this.handlers) this.handlers = new Map();

    if (!this.handlers.has(event)) {
      this.handlers.set(event, new Set());
    }

    this.handlers.get(event).add(handler);
    return () => this.handlers.get(event)?.delete(handler);
  }

`;

  src = src.replace(classMatch[0], classMatch[0] + insertion);
}

if (!src.includes("publish(")) {
  const classMatch = src.match(/class\s+EventBus\s*\{/);

  if (!classMatch) {
    console.error("Unable to locate EventBus class");
    process.exit(1);
  }

  const insertion = `
  publish(event, payload) {
    if (typeof this.emit === "function") {
      return this.emit(event, payload);
    }

    const handlers = this.handlers?.get(event);

    if (!handlers) return false;

    for (const handler of handlers) {
      handler(payload);
    }

    return true;
  }

`;

  src = src.replace(classMatch[0], classMatch[0] + insertion);
}

fs.writeFileSync(file, src);
NODE

node --check "$EVENT_FILE"

echo "✓ EventBus syntax valid"

echo
echo "[3] Remove invalid shared /tmp socket artifact"
echo "--------------------------------------------------------------"

rm -f /tmp/eb-socket-response 2>/dev/null || true

SOCKET_TMP="$ROOT/.runtime/socket-response"
rm -f "$SOCKET_TMP" 2>/dev/null || true

echo "✓ Runtime socket artifact cleaned"

echo
echo "[4] Verify EventBus"
echo "--------------------------------------------------------------"

node <<'NODE'
const { EventBus } = require("./framework");

const bus = new EventBus();

let received = false;

const handler = payload => {
  if (payload?.ok === true) received = true;
};

if (typeof bus.subscribe === "function") {
  bus.subscribe("eb.integration.test", handler);
} else if (typeof bus.on === "function") {
  bus.on("eb.integration.test", handler);
} else {
  throw new Error("EventBus has neither subscribe() nor on()");
}

if (typeof bus.publish === "function") {
  bus.publish("eb.integration.test", { ok: true });
} else if (typeof bus.emit === "function") {
  bus.emit("eb.integration.test", { ok: true });
} else {
  throw new Error("EventBus has neither publish() nor emit()");
}

if (!received) {
  throw new Error("EventBus round-trip failed");
}

console.log("✓ EventBus round-trip successful");
NODE

echo
echo "[5] Verify realtime"
echo "--------------------------------------------------------------"

SOCKET_RESPONSE="$(
  curl -sS --max-time 8 \
    "http://127.0.0.1:3001/socket.io/?EIO=4&transport=polling" \
    2>/dev/null || true
)"

if printf '%s' "$SOCKET_RESPONSE" | grep -q '"sid"'; then
  echo "✓ Socket.IO® handshake successful"
else
  echo "✗ Socket.IO® handshake failed"
  printf '%s\n' "$SOCKET_RESPONSE"
  exit 1
fi

echo
echo "[6] Verify application routes"
echo "--------------------------------------------------------------"

for route in /request /ops; do
  code="$(
    curl -sS -o /dev/null -w '%{http_code}' \
      --max-time 8 \
      "http://127.0.0.1:3000${route}" \
      2>/dev/null || true
  )"

  case "$code" in
    2*|3*) echo "✓ $route HTTP $code" ;;
    *) echo "✗ $route HTTP $code"; exit 1 ;;
  esac
done

echo
echo "[7] Verify framework tests"
echo "--------------------------------------------------------------"

node ./tests/run.js

echo
echo "[8] Verify application modules"
echo "--------------------------------------------------------------"

node <<'NODE'
const modules = require("./apps/request-runner");

const expected = [
  "customers",
  "requests",
  "orders",
  "dispatch",
  "drivers",
  "locations",
  "scheduling",
  "payments",
  "notifications",
  "operations",
  "administration"
];

const names = modules.map(m => m.name);

for (const name of expected) {
  if (!names.includes(name)) {
    throw new Error(`Missing module: ${name}`);
  }
}

console.log(`✓ ${names.length}/${expected.length} application modules loaded`);
NODE

echo
echo "[9] Verify JavaScript syntax"
echo "--------------------------------------------------------------"

while IFS= read -r file; do
  case "$file" in
    ./.next/*|./node_modules/*|./.platform-backup-*/*)
      continue
      ;;
  esac

  node --check "$file" >/dev/null
done < <(
  find framework apps bin tests -type f -name '*.js' 2>/dev/null | sort
)

echo "✓ JavaScript syntax clean"

echo
echo "[10] Verify Next.js development mode"
echo "--------------------------------------------------------------"

if [ -f package.json ]; then
  node <<'NODE'
const pkg = require("./package.json");

console.log("package:", pkg.name);
console.log("scripts:", JSON.stringify(pkg.scripts, null, 2));

if (!pkg.scripts?.dev) {
  console.error("Missing npm dev script");
  process.exit(1);
}
NODE
else
  echo "✗ package.json missing"
  exit 1
fi

echo
echo "[11] Build production application"
echo "--------------------------------------------------------------"

if npm run build; then
  echo "✓ Production build completed"
else
  echo "✗ Production build failed"
  exit 1
fi

echo
echo "[12] Verify production build"
echo "--------------------------------------------------------------"

if [ -f ".next/BUILD_ID" ]; then
  echo "✓ .next/BUILD_ID exists"
else
  echo "✗ Production BUILD_ID missing"
  exit 1
fi

echo
echo "[13] Final platform status"
echo "--------------------------------------------------------------"

./EB_PLATFORM.sh status

echo
echo "=============================================================="
echo " EB PLATFORM® — REPAIR COMPLETE"
echo "=============================================================="
echo
echo "✓ EventBus compatibility fixed"
echo "✓ Realtime handshake verified"
echo "✓ Customer route verified"
echo "✓ Operations route verified"
echo "✓ Framework tests verified"
echo "✓ Application modules verified"
echo "✓ JavaScript syntax verified"
echo "✓ Production build verified"
echo
echo "Customer:"
echo "  http://127.0.0.1:3000/request"
echo
echo "Operations:"
echo "  http://127.0.0.1:3000/ops"
echo
echo "Realtime:"
echo "  http://127.0.0.1:3001"
echo
