#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

echo "=============================================================="
echo " EB PLATFORM® — REAL LAN ACCESS"
echo "=============================================================="
echo

get_lan_ip() {
    local ip=""

    if command -v ip >/dev/null 2>&1; then
        ip="$(
            ip -4 addr show 2>/dev/null |
            awk '
                /inet / && $2 !~ /^127\./ {
                    split($2,a,"/")
                    print a[1]
                    exit
                }
            '
        )"
    fi

    if [ -z "$ip" ] && command -v ifconfig >/dev/null 2>&1; then
        ip="$(
            ifconfig 2>/dev/null |
            awk '
                /inet / && $2 !~ /^127\./ {
                    print $2
                    exit
                }
            '
        )"
    fi

    printf '%s' "${ip:-127.0.0.1}"
}

LAN_IP="$(get_lan_ip)"

echo "[1] NETWORK"
echo "--------------------------------------------------------------"
echo "Detected LAN IP: $LAN_IP"
echo

if [ "$LAN_IP" = "127.0.0.1" ]; then
    echo "⚠ Could not detect a LAN IP."
    echo
    echo "Run:"
    echo "  ip -4 addr"
    echo
    echo "Make sure the phone is connected to Wi-Fi."
    exit 1
fi

echo "✓ LAN address detected"
echo

echo "[2] VERIFY NEXT CONFIGURATION"
echo "--------------------------------------------------------------"

if grep -Rqs \
    --exclude-dir=node_modules \
    --exclude-dir=.next \
    "0.0.0.0" \
    server.js package.json next.config.js 2>/dev/null; then
    echo "✓ Application has a 0.0.0.0 binding configuration"
else
    echo "⚠ No explicit 0.0.0.0 binding found"
fi

echo

echo "[3] VERIFY PORT 3000"
echo "--------------------------------------------------------------"

if curl -fsS --max-time 5 \
    "http://${LAN_IP}:3000/api/health" >/dev/null 2>&1; then
    echo "✓ API reachable through LAN address"
else
    echo "⚠ API not reachable through LAN address"
fi

echo

echo "[4] VERIFY CUSTOMER"
echo "--------------------------------------------------------------"

CUSTOMER_CODE="$(
    curl -sS \
        -o /dev/null \
        -w '%{http_code}' \
        --max-time 5 \
        "http://${LAN_IP}:3000/request" \
        2>/dev/null || true
)"

echo "Customer HTTP: $CUSTOMER_CODE"

case "$CUSTOMER_CODE" in
    2*|3*)
        echo "✓ Customer application reachable"
        ;;
    *)
        echo "✗ Customer application NOT reachable"
        ;;
esac

echo

echo "[5] VERIFY OPERATIONS"
echo "--------------------------------------------------------------"

OPS_CODE="$(
    curl -sS \
        -o /dev/null \
        -w '%{http_code}' \
        --max-time 5 \
        "http://${LAN_IP}:3000/ops" \
        2>/dev/null || true
)"

echo "Operations HTTP: $OPS_CODE"

case "$OPS_CODE" in
    2*|3*)
        echo "✓ Operations application reachable"
        ;;
    *)
        echo "✗ Operations application NOT reachable"
        ;;
esac

echo

echo "[6] VERIFY REALTIME"
echo "--------------------------------------------------------------"

RT_CODE="$(
    curl -sS \
        -o /dev/null \
        -w '%{http_code}' \
        --max-time 5 \
        "http://${LAN_IP}:3001/health" \
        2>/dev/null || true
)"

echo "Realtime HTTP: $RT_CODE"

case "$RT_CODE" in
    2*|3*)
        echo "✓ Realtime reachable"
        ;;
    *)
        echo "✗ Realtime NOT reachable"
        ;;
esac

echo

echo "=============================================================="
echo " EB PLATFORM® — COMPUTER ACCESS"
echo "=============================================================="
echo
echo "From your COMPUTER browser, open:"
echo
echo "CUSTOMER:"
echo "  http://${LAN_IP}:3000/request"
echo
echo "OPERATIONS:"
echo "  http://${LAN_IP}:3000/ops"
echo
echo "API:"
echo "  http://${LAN_IP}:3000/api/health"
echo
echo "REALTIME:"
echo "  http://${LAN_IP}:3001/health"
echo
echo "=============================================================="
echo
echo "IMPORTANT:"
echo "Phone and computer must be connected to the same Wi-Fi network."
echo
