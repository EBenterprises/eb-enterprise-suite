#!/data/data/com.termux/files/usr/bin/bash
set -u

cd "$(dirname "$0")" || exit 1

clear

LOG_FILE="$PWD/.request-runner-server.log"

echo "=============================================================="
echo " REQUEST RUNNER® — LAN DEVELOPMENT START"
echo "=============================================================="

echo
echo "[1] SERVER BIND"
if grep -q '0\.0\.0\.0' server.js; then
    echo "✓ 0.0.0.0 binding"
else
    echo "✗ 0.0.0.0 binding missing"
    exit 1
fi

echo
echo "[2] NODE SYNTAX"
node --check server.js
echo "✓ server.js valid"

echo
echo "[3] LAN ADDRESS"

LAN_IP="$(
    ifconfig wlan0 2>/dev/null |
    awk '
        /inet / {
            for (i=1; i<=NF; i++) {
                if ($i=="inet") {
                    print $(i+1)
                    exit
                }
            }
        }
    '
)"

if [ -z "$LAN_IP" ]; then
    LAN_IP="$(
        ifconfig 2>/dev/null |
        awk '
            /inet / {
                for (i=1; i<=NF; i++) {
                    if ($i=="inet" && $(i+1) !~ /^127\./) {
                        print $(i+1)
                        exit
                    }
                }
            }
        '
    )"
fi

if [ -z "$LAN_IP" ]; then
    echo "✗ No LAN IPv4 detected"
    exit 1
fi

echo "✓ LAN IP: $LAN_IP"

echo
echo "[4] STOP EXISTING REQUEST RUNNER® SERVER"

PIDS="$(
    ps -A 2>/dev/null |
    awk -v target="$HOME/request-runner/server.js" '
        /node/ && index($0,target) {
            print $2
        }
    '
)"

if [ -n "$PIDS" ]; then
    kill $PIDS 2>/dev/null || true
    sleep 1
    echo "✓ Previous server stopped"
else
    echo "✓ No previous server found"
fi

echo
echo "[5] START SERVER"

: > "$LOG_FILE" 2>/dev/null || {
    echo "✗ Cannot create project log"
    exit 1
}

nohup node server.js >"$LOG_FILE" 2>&1 &
SERVER_PID=$!

sleep 2

if kill -0 "$SERVER_PID" 2>/dev/null; then
    echo "✓ Server running — PID $SERVER_PID"
else
    echo "✗ Server failed to start"
    echo
    echo "Server log:"
    tail -n 30 "$LOG_FILE" 2>/dev/null || true
    exit 1
fi

echo
echo "[6] LOCAL HTTP"

LOCAL_CODE="$(
    curl -sS \
        -o /dev/null \
        -w '%{http_code}' \
        --max-time 5 \
        http://127.0.0.1:3000/ 2>/dev/null
)"

if [ "$LOCAL_CODE" = "200" ]; then
    echo "✓ Local HTTP 200"
else
    echo "✗ Local HTTP $LOCAL_CODE"
    tail -n 30 "$LOG_FILE" 2>/dev/null || true
    exit 1
fi

echo
echo "[7] LAN HTTP"

LAN_CODE="$(
    curl -sS \
        -o /dev/null \
        -w '%{http_code}' \
        --max-time 5 \
        "http://$LAN_IP:3000/" 2>/dev/null
)"

if [ "$LAN_CODE" = "200" ]; then
    echo "✓ LAN HTTP 200"
else
    echo "✗ LAN HTTP $LAN_CODE"
    tail -n 30 "$LOG_FILE" 2>/dev/null || true
    exit 1
fi

echo
echo "=============================================================="
echo " REQUEST RUNNER® — COMPUTER ACCESS READY"
echo "=============================================================="
echo
echo "MAIN:"
echo "http://$LAN_IP:3000/"
echo
echo "REQUEST:"
echo "http://$LAN_IP:3000/request"
echo
echo "OPERATIONS:"
echo "http://$LAN_IP:3000/ops"
echo
echo "HEALTH:"
echo "http://$LAN_IP:3000/api/health"
echo
echo "PHONE IP: $LAN_IP"
echo "SERVER: 0.0.0.0:3000"
echo
echo "LOG: $LOG_FILE"
echo
echo "=============================================================="
