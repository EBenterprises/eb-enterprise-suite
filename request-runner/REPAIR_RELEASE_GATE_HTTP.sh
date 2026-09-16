#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

STAMP="$(date '+%Y%m%d-%H%M%S')"
BACKUP="$ROOT/.release-gate-http-backup-$STAMP"

PASS=0
FAIL=0

ok() {
    echo "✓ $1"
    PASS=$((PASS+1))
}

fail() {
    echo "✗ $1"
    FAIL=$((FAIL+1))
}

echo
echo "=============================================================="
echo " REQUEST RUNNER® — RELEASE GATE HTTP REPAIR"
echo " INSPECT → BACKUP → PATCH → VERIFY"
echo "=============================================================="
echo

echo "[1] INSPECTION"
echo "--------------------------------------------------------------"

[ -f REQUEST_RUNNER_RELEASE_GATE.sh ] &&
    ok "Release gate exists" ||
    fail "Release gate missing"

[ -f EB_PLATFORM.sh ] &&
    ok "Platform script exists" ||
    fail "Platform script missing"

if [ "$FAIL" -ne 0 ]; then
    echo
    echo "INSPECTION FAILED — NO MUTATION."
    exit 1
fi

echo
echo "[2] CURRENT HTTP CHECK"
echo "--------------------------------------------------------------"

http_code() {
    curl -sS \
        -o /dev/null \
        -w '%{http_code}' \
        --max-time 5 \
        "$1" 2>/dev/null || true
}

CUSTOMER="$(http_code http://127.0.0.1:3000/request)"
OPS="$(http_code http://127.0.0.1:3000/ops)"

case "$CUSTOMER" in
    2*|3*) ok "Customer /request → HTTP $CUSTOMER" ;;
    *) fail "Customer /request → HTTP ${CUSTOMER:-000}" ;;
esac

case "$OPS" in
    2*|3*) ok "Operations /ops → HTTP $OPS" ;;
    *) fail "Operations /ops → HTTP ${OPS:-000}" ;;
esac

if [ "$FAIL" -ne 0 ]; then
    echo
    echo "LIVE SERVICE IS NOT HEALTHY — NO PATCH."
    exit 1
fi

echo
echo "[3] SAFETY BACKUP"
echo "--------------------------------------------------------------"

mkdir -p "$BACKUP"
cp -p REQUEST_RUNNER_RELEASE_GATE.sh "$BACKUP/"

ok "Backup created: $BACKUP"

echo
echo "[4] LOCATE HTTP CHECK"
echo "--------------------------------------------------------------"

grep -nE \
    '127\.0\.0\.1:3000|/request|/ops|HTTP 000|LIVE APPLICATION' \
    REQUEST_RUNNER_RELEASE_GATE.sh |
    head -n 80 || true

echo
echo "[5] RELEASE GATE RECHECK"
echo "--------------------------------------------------------------"

if ./REQUEST_RUNNER_RELEASE_GATE.sh; then
    ok "Release gate GREEN"
else
    echo
    echo "Release gate still reports RED."
    echo
    echo "The live services are healthy, so the remaining failure"
    echo "is isolated to release-gate logic."
    echo
    echo "Backup preserved:"
    echo "$BACKUP"
    exit 1
fi

echo
echo "=============================================================="
echo " RESULT"
echo "=============================================================="
echo
echo "PASS: $PASS"
echo "FAIL: $FAIL"
echo "Backup: $BACKUP"
echo

if [ "$FAIL" -eq 0 ]; then
    echo "STATUS: GREEN"
    echo "HTTP SERVICE + RELEASE GATE VERIFIED"
else
    echo "STATUS: RED"
    exit 1
fi

echo "=============================================================="
