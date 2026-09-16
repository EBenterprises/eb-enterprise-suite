#!/data/data/com.termux/files/usr/bin/bash
set -u

clear

echo "=============================================================="
echo " REQUEST RUNNER® — NETWORK STACK CHECK"
echo " READ-ONLY / NO MUTATION"
echo "=============================================================="

echo
echo "[1] ROUTING"
echo "--------------------------------------------------------------"
ip route 2>/dev/null | head -n 15 || true

echo
echo "[2] IPv4 INTERFACES"
echo "--------------------------------------------------------------"
ip -4 addr 2>/dev/null |
awk '
/^[0-9]+: / {
    iface=$2
    sub(/:$/, "", iface)
}
/inet / {
    print iface, $2
}
' | head -n 30 || true

echo
echo "[3] DEFAULT ROUTE"
echo "--------------------------------------------------------------"
ip route 2>/dev/null |
awk '$1=="default" {print}' |
head -n 5 || true

echo
echo "[4] PROXY VARIABLES"
echo "--------------------------------------------------------------"

for V in \
    HTTP_PROXY HTTPS_PROXY ALL_PROXY \
    http_proxy https_proxy all_proxy \
    NO_PROXY no_proxy
do
    eval "VALUE=\${$V-}"

    if [ -n "$VALUE" ]; then
        echo "$V=$VALUE"
    fi
done

if ! env | grep -qiE '^(HTTP|HTTPS|ALL|NO)_PROXY='; then
    echo "No proxy environment variables detected"
fi

echo
echo "[5] TOR / VPN / PROXY PROCESSES"
echo "--------------------------------------------------------------"

ps -A 2>/dev/null |
grep -Ei \
'tor|redsocks|tun2socks|sing-box|clash|v2ray|xray|proxy|vpn|wireguard|openvpn' |
grep -v grep |
head -n 40 || echo "No matching processes detected"

echo
echo "[6] NETWORK TUNNEL INTERFACES"
echo "--------------------------------------------------------------"

ip link 2>/dev/null |
grep -Ei \
'tun|tap|wg|vpn|proxy|tor|clash|sing|v2ray|xray' |
head -n 30 || echo "No obvious tunnel interface detected"

echo
echo "[7] LISTENING SERVICES"
echo "--------------------------------------------------------------"

if command -v ss >/dev/null 2>&1; then
    ss -lnt 2>/dev/null | head -n 25
elif command -v netstat >/dev/null 2>&1; then
    netstat -lnt 2>/dev/null | head -n 25
else
    echo "ss/netstat unavailable"
fi

echo
echo "[8] TERMUX WIFI"
echo "--------------------------------------------------------------"

if command -v termux-wifi-connectioninfo >/dev/null 2>&1; then
    termux-wifi-connectioninfo 2>/dev/null | head -n 40
else
    echo "termux-wifi-connectioninfo unavailable"
fi

echo
echo "[9] ANDROID NETWORK PROPERTIES"
echo "--------------------------------------------------------------"

getprop 2>/dev/null |
grep -Ei \
'dhcp|dns|net\.hostname|net\.dns|wifi|wlan' |
head -n 40 || true

echo
echo "[10] CONNECTIVITY"
echo "--------------------------------------------------------------"

printf "Loopback: "
if curl -sS -o /dev/null --max-time 3 http://127.0.0.1:3000/ 2>/dev/null; then
    echo "HTTP service reachable"
else
    echo "No local Request Runner® response"
fi

printf "DNS: "
if getent hosts google.com >/dev/null 2>&1; then
    echo "WORKING"
else
    echo "FAILED"
fi

printf "Internet HTTPS: "
if curl -sS -I -o /dev/null --max-time 5 https://example.com 2>/dev/null; then
    echo "WORKING"
else
    echo "FAILED"
fi

echo
echo "=============================================================="
echo " NETWORK CHECK COMPLETE"
echo " READ-ONLY — NO NETWORK SETTINGS CHANGED"
echo "=============================================================="
