#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

PORT="${PORT:-3010}"
HOST="127.0.0.1"
BASE="http://${HOST}:${PORT}"
RUNTIME="$ROOT/.runtime"

mkdir -p "$RUNTIME"

echo "=============================================================="
echo " EB PLATFORM® — PRODUCTION REALITY VERIFICATION"
echo "=============================================================="
echo

echo "[1] VERIFY BUILD"
echo "--------------------------------------------------------------"

if [ ! -f ".next/BUILD_ID" ]; then
    echo "✗ Production build missing"
    echo "Run: ./NEXT_FIX_MODULE_NOT_FOUND.sh"
    exit 1
fi

echo "✓ BUILD_ID: $(cat .next/BUILD_ID)"
echo

echo "[2] STOP OLD REQUEST-RUNNER SERVERS"
echo "--------------------------------------------------------------"

pkill -f "next start" 2>/dev/null || true
pkill -f "next-server" 2>/dev/null || true

sleep 1

echo "✓ Old Next production processes stopped"
echo

echo "[3] START PRODUCTION SERVER"
echo "--------------------------------------------------------------"

LOG="$RUNTIME/production-reality.log"
PIDFILE="$RUNTIME/production-reality.pid"

rm -f "$PIDFILE"

nohup npm run start -- \
    --hostname "$HOST" \
    --port "$PORT" \
    > "$LOG" 2>&1 &

PID=$!

echo "$PID" > "$PIDFILE"

echo "✓ PID: $PID"
echo "✓ Port: $PORT"
echo

echo "[4] WAIT FOR SERVER"
echo "--------------------------------------------------------------"

READY=0

for i in $(seq 1 30); do
    if curl -fsS --max-time 2 \
        "$BASE/api/health" \
        >/dev/null 2>&1; then
        READY=1
        break
    fi

    if ! kill -0 "$PID" 2>/dev/null; then
        echo "✗ Production server exited"
        echo
        tail -n 100 "$LOG" || true
        exit 1
    fi

    sleep 1
done

if [ "$READY" -ne 1 ]; then
    echo "✗ Production server did not become healthy"
    echo
    tail -n 100 "$LOG" || true
    exit 1
fi

echo "✓ Production server responding"
echo

echo "[5] HEALTH API"
echo "--------------------------------------------------------------"

HEALTH="$(curl -fsS \
    --max-time 5 \
    "$BASE/api/health")"

printf '%s\n' "$HEALTH"

echo

echo "[6] CUSTOMER CRUD HTTP TEST"
echo "--------------------------------------------------------------"

CUSTOMER_ID="production-reality-$(date +%s)"

CREATE_RESPONSE="$(
    curl -fsS \
        --max-time 5 \
        -X POST \
        -H 'Content-Type: application/json' \
        -d "{\"id\":\"$CUSTOMER_ID\",\"type\":\"production-verification\",\"name\":\"Reality Test\",\"value\":\"created\"}" \
        "$BASE/api/customers"
)"

printf '%s\n' "$CREATE_RESPONSE"

echo "$CREATE_RESPONSE" | grep -q '"ok":true'

echo "✓ HTTP CREATE"
echo

echo "[7] CUSTOMER READ"
echo "--------------------------------------------------------------"

READ_RESPONSE="$(
    curl -fsS \
        --max-time 5 \
        "$BASE/api/customers/$CUSTOMER_ID"
)"

printf '%s\n' "$READ_RESPONSE"

echo "$READ_RESPONSE" | grep -q "$CUSTOMER_ID"

echo "✓ HTTP READ"
echo

echo "[8] CUSTOMER UPDATE"
echo "--------------------------------------------------------------"

UPDATE_RESPONSE="$(
    curl -fsS \
        --max-time 5 \
        -X PATCH \
        -H 'Content-Type: application/json' \
        -d '{"value":"updated"}' \
        "$BASE/api/customers/$CUSTOMER_ID"
)"

printf '%s\n' "$UPDATE_RESPONSE"

echo "$UPDATE_RESPONSE" | grep -q '"ok":true'
echo "$UPDATE_RESPONSE" | grep -q '"updated"'

echo "✓ HTTP UPDATE"
echo

echo "[9] CUSTOMER DELETE"
echo "--------------------------------------------------------------"

DELETE_RESPONSE="$(
    curl -fsS \
        --max-time 5 \
        -X DELETE \
        "$BASE/api/customers/$CUSTOMER_ID"
)"

printf '%s\n' "$DELETE_RESPONSE"

echo "$DELETE_RESPONSE" | grep -q '"ok":true'

echo "✓ HTTP DELETE"
echo

echo "[10] DELETE VERIFICATION"
echo "--------------------------------------------------------------"

DELETE_STATUS="$(
    curl -sS \
        --max-time 5 \
        -o "$RUNTIME/delete-check.json" \
        -w '%{http_code}' \
        "$BASE/api/customers/$CUSTOMER_ID"
)"

cat "$RUNTIME/delete-check.json"

echo

if [ "$DELETE_STATUS" != "404" ]; then
    echo "✗ Deleted record still accessible"
    exit 1
fi

echo "✓ DELETE persisted"
echo

echo "[11] DIRECT PERSISTENCE VERIFICATION"
echo "--------------------------------------------------------------"

node - <<'NODE'
const platform = require("./framework");

if (!platform.JsonRepository) {
    console.log("JsonRepository export not present on framework root; using application service.");
}

const service = require("./framework/application-service");

const collection = "__production_persistence_test__";

(async () => {
    const repository = service.repository(collection);

    if (typeof repository.clear === "function") {
        await repository.clear();
    }

    const created = await service.create(collection, {
        type: "production-persistence",
        value: "created"
    });

    if (!created || !created.id) {
        throw new Error("CREATE failed");
    }

    const read = await service.get(collection, created.id);

    if (!read || read.value !== "created") {
        throw new Error("READ failed");
    }

    const updated = await service.update(
        collection,
        created.id,
        { value: "updated" }
    );

    if (!updated || updated.value !== "updated") {
        throw new Error("UPDATE failed");
    }

    const removed = await service.remove(
        collection,
        created.id
    );

    if (!removed) {
        throw new Error("DELETE failed");
    }

    const deleted = await service.get(
        collection,
        created.id
    );

    if (deleted) {
        throw new Error("DELETE persistence verification failed");
    }

    if (typeof repository.clear === "function") {
        await repository.clear();
    }

    console.log("✓ Persistent CREATE");
    console.log("✓ Persistent READ");
    console.log("✓ Persistent UPDATE");
    console.log("✓ Persistent DELETE");
    console.log("✓ Durable persistence verified");
})().catch(error => {
    console.error(error);
    process.exit(1);
});
NODE

echo

echo "[12] PRODUCTION PROCESS"
echo "--------------------------------------------------------------"

if kill -0 "$PID" 2>/dev/null; then
    echo "✓ Server alive"
else
    echo "✗ Server stopped unexpectedly"
    exit 1
fi

echo

echo "[13] PORT"
echo "--------------------------------------------------------------"

curl -sS \
    --max-time 5 \
    -o /dev/null \
    -w 'HTTP %{http_code}\n' \
    "$BASE/api/health"

echo

echo "[14] PRODUCTION LOG"
echo "--------------------------------------------------------------"

tail -n 50 "$LOG" || true

echo

echo "=============================================================="
echo " EB PLATFORM® — PRODUCTION REALITY PASSED"
echo "=============================================================="
echo
echo "Production:"
echo "  $BASE"
echo
echo "Health:"
echo "  $BASE/api/health"
echo
echo "Customer API:"
echo "  $BASE/api/customers"
echo
echo "✓ Production server"
echo "✓ Health API"
echo "✓ HTTP CREATE"
echo "✓ HTTP READ"
echo "✓ HTTP UPDATE"
echo "✓ HTTP DELETE"
echo "✓ Delete persistence"
echo "✓ Direct persistence"
echo
echo "PID:"
echo "  $PID"
echo
echo "LOG:"
echo "  $LOG"
echo
