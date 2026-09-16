#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

echo "=== REQUEST RUNNER® — POST-RELEASE HARDENING ==="
echo

# ------------------------------------------------------------
# 1. FIX / VERIFY LAN ADDRESS
# ------------------------------------------------------------

LAN_IP=""

if command -v ip >/dev/null 2>&1; then
    LAN_IP="$(
        ip route get 1.1.1.1 2>/dev/null |
        awk '{
            for (i=1; i<=NF; i++)
                if ($i=="src") {
                    print $(i+1)
                    exit
                }
        }'
    )"
fi

if [ -z "$LAN_IP" ]; then
    LAN_IP="$(
        ip -4 addr show 2>/dev/null |
        awk '/inet / && $2 !~ /^127\./ {
            sub("/.*","",$2)
            print $2
            exit
        }'
    )"
fi

[ -n "$LAN_IP" ] || LAN_IP="127.0.0.1"

echo "[1] NETWORK"
echo "--------------------------------------------------------------"
echo "LAN IP: $LAN_IP"
echo "Customer: http://$LAN_IP:3000/request"
echo "Operations: http://$LAN_IP:3000/ops"
echo "Realtime: http://$LAN_IP:3001"

# ------------------------------------------------------------
# 2. LOCAL APPLICATION
# ------------------------------------------------------------

echo
echo "[2] LOCAL ROUTES"
echo "--------------------------------------------------------------"

check() {
    local name="$1"
    local url="$2"
    local code

    code="$(
        curl -sS \
            -o /dev/null \
            -w '%{http_code}' \
            --max-time 8 \
            "$url" 2>/dev/null || true
    )"

    case "$code" in
        2*|3*) echo "✓ $name — HTTP $code" ;;
        *)     echo "✗ $name — HTTP $code"; return 1 ;;
    esac
}

check "Customer /request" "http://127.0.0.1:3000/request"
check "Operations /ops" "http://127.0.0.1:3000/ops"

# ------------------------------------------------------------
# 3. REALTIME
# ------------------------------------------------------------

echo
echo "[3] REALTIME"
echo "--------------------------------------------------------------"

SOCKET_RESPONSE="$(
    curl -sS \
        --max-time 8 \
        "http://127.0.0.1:3001/socket.io/?EIO=4&transport=polling" \
        2>/dev/null || true
)"

if echo "$SOCKET_RESPONSE" | grep -q '"sid"'; then
    echo "✓ Socket.IO handshake"
else
    echo "✗ Socket.IO handshake"
    exit 1
fi

# ------------------------------------------------------------
# 4. ENTRYPOINTS
# ------------------------------------------------------------

echo
echo "[4] ENTRYPOINTS"
echo "--------------------------------------------------------------"

bash -n EB_PLATFORM.sh
bash -n start.sh
bash -n launch.sh
bash -n REQUEST_RUNNER_RELEASE_GATE.sh

echo "✓ Shell syntax"

# ------------------------------------------------------------
# 5. STATUS
# ------------------------------------------------------------

echo
echo "[5] PLATFORM STATUS"
echo "--------------------------------------------------------------"

./EB_PLATFORM.sh status

# ------------------------------------------------------------
# 6. FINAL RELEASE GATE
# ------------------------------------------------------------

echo
echo "[6] FINAL RELEASE GATE"
echo "--------------------------------------------------------------"

./REQUEST_RUNNER_RELEASE_GATE.sh

echo
echo "=============================================================="
echo " REQUEST RUNNER® — POST-RELEASE HARDENING COMPLETE"
echo "=============================================================="
echo
echo "STATUS: GREEN"
echo
echo "Customer:"
echo "  http://$LAN_IP:3000/request"
echo
echo "Operations:"
echo "  http://$LAN_IP:3000/ops"
echo
echo "Realtime:"
echo "  http://$LAN_IP:3001"
echo
