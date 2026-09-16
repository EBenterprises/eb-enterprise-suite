#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$ROOT/.platform-backup-$STAMP"

echo "=== REQUEST RUNNER® — FINAL PRODUCTION HARDENING ==="
echo

# ------------------------------------------------------------
# 1. CREATE IMMUTABLE-STYLE RELEASE SNAPSHOT
# ------------------------------------------------------------

echo "[1] RELEASE SNAPSHOT"
echo "--------------------------------------------------------------"

mkdir -p "$BACKUP"

cp -a \
    package.json \
    server.js \
    next.config.js \
    EB_PLATFORM.sh \
    start.sh \
    launch.sh \
    framework \
    apps \
    bin \
    tests \
    "$BACKUP/" 2>/dev/null

echo "✓ Snapshot created"
echo "  $BACKUP"

# ------------------------------------------------------------
# 2. VERIFY ENTRYPOINTS
# ------------------------------------------------------------

echo
echo "[2] ENTRYPOINTS"
echo "--------------------------------------------------------------"

for file in \
    EB_PLATFORM.sh \
    start.sh \
    launch.sh \
    REQUEST_RUNNER_RELEASE_GATE.sh
do
    [ -x "$ROOT/$file" ] || chmod 700 "$ROOT/$file"
    bash -n "$ROOT/$file"
    echo "✓ $file"
done

# ------------------------------------------------------------
# 3. VERIFY CURRENT SERVICES
# ------------------------------------------------------------

echo
echo "[3] SERVICE STATUS"
echo "--------------------------------------------------------------"

./EB_PLATFORM.sh status

# ------------------------------------------------------------
# 4. VERIFY CUSTOMER
# ------------------------------------------------------------

echo
echo "[4] CUSTOMER SURFACE"
echo "--------------------------------------------------------------"

CODE="$(
    curl -sS \
        -o "$ROOT/.customer-check" \
        -w '%{http_code}' \
        --max-time 8 \
        http://127.0.0.1:3000/request \
        2>/dev/null || true
)"

case "$CODE" in
    2*|3*) echo "✓ Customer /request — HTTP $CODE" ;;
    *) echo "✗ Customer /request — HTTP $CODE"; exit 1 ;;
esac

# ------------------------------------------------------------
# 5. VERIFY OPERATIONS
# ------------------------------------------------------------

echo
echo "[5] OPERATIONS SURFACE"
echo "--------------------------------------------------------------"

CODE="$(
    curl -sS \
        -o "$ROOT/.ops-check" \
        -w '%{http_code}' \
        --max-time 8 \
        http://127.0.0.1:3000/ops \
        2>/dev/null || true
)"

case "$CODE" in
    2*|3*) echo "✓ Operations /ops — HTTP $CODE" ;;
    *) echo "✗ Operations /ops — HTTP $CODE"; exit 1 ;;
esac

# ------------------------------------------------------------
# 6. VERIFY REALTIME
# ------------------------------------------------------------

echo
echo "[6] REALTIME"
echo "--------------------------------------------------------------"

SOCKET="$(
    curl -sS \
        --max-time 8 \
        'http://127.0.0.1:3001/socket.io/?EIO=4&transport=polling' \
        2>/dev/null || true
)"

if echo "$SOCKET" | grep -q '"sid"'; then
    echo "✓ Socket.IO Engine.IO handshake"
else
    echo "✗ Socket.IO handshake"
    exit 1
fi

# ------------------------------------------------------------
# 7. CLEAN TEMP CHECK FILES
# ------------------------------------------------------------

rm -f \
    "$ROOT/.customer-check" \
    "$ROOT/.ops-check"

echo
echo "[7] CLEANUP"
echo "--------------------------------------------------------------"
echo "✓ Temporary verification files removed"

# ------------------------------------------------------------
# 8. FINAL RELEASE GATE
# ------------------------------------------------------------

echo
echo "[8] FINAL RELEASE GATE"
echo "--------------------------------------------------------------"

./REQUEST_RUNNER_RELEASE_GATE.sh

echo
echo "=============================================================="
echo " REQUEST RUNNER® — PRODUCTION HARDENING COMPLETE"
echo "=============================================================="
echo
echo "STATUS: GREEN"
echo "RELEASE: READY"
echo "SNAPSHOT: $BACKUP"
echo
