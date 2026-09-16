#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
cd "$(dirname "$0")"

C=.omega/certification
T=.omega/tmp
P=.omega/production.pid
L=$T/final.log
mkdir -p "$C" "$T"

rm -f "$C/OMEGA_CERTIFIED.txt" "$C/RUNTIME_STATE.txt"
rm -rf .next
: > "$L"

fail(){ echo "FAIL: $1"; tail -30 "$L" 2>/dev/null; exit 1; }
run(){ "$@" >>"$L" 2>&1 || fail "$1"; }

echo "OMEGA® FAST FINAL"

# Repair runtime contract
node - <<'NODE' || exit 1
const fs=require("fs");
const p=JSON.parse(fs.readFileSync("package.json"));
p.scripts=p.scripts||{};
p.scripts.start="next start";
p.scripts.build="next build --webpack";
p.scripts.dev="next dev --webpack";
fs.writeFileSync("package.json",JSON.stringify(p,null,2)+"\n");
NODE

# Keep lockfile synchronized without noisy output
run npm install --package-lock-only --ignore-scripts

# Fast structural checks
for f in package.json package-lock.json bin/omega.js; do
  test -s "$f" || fail "$f"
done
for d in src/app tests public data; do
  test -d "$d" || fail "$d"
done

# CLI
run node bin/omega.js status
run node bin/omega.js capabilities
run node bin/omega.js metrics

# Production build
run npm run build
test -s .next/BUILD_ID || fail "BUILD_ID"

# Tests
run npm test

# Stop only our recorded server
if [ -s "$P" ]; then
  OLD="$(cat "$P" 2>/dev/null || true)"
  [ -n "$OLD" ] && kill "$OLD" 2>/dev/null || true
fi
rm -f "$P"

# Production server
nohup npm run start -- --hostname 0.0.0.0 >"$T/server.log" 2>&1 &
PID=$!
echo "$PID" > "$P"

READY=0
for i in $(seq 1 20); do
  if curl -fsS --max-time 1 http://127.0.0.1:3000 >/dev/null 2>&1; then
    READY=1
    break
  fi
  kill -0 "$PID" 2>/dev/null || break
  sleep 1
done

[ "$READY" = 1 ] || {
  cat "$T/server.log" >>"$L" 2>/dev/null || true
  fail "production server"
}

HTTP="$(curl -sS --max-time 5 -o "$T/home.html" -w '%{http_code}' http://127.0.0.1:3000)"
[ "$HTTP" = 200 ] || fail "HTTP $HTTP"

grep -qi '<html' "$T/home.html" || fail "HTML"

LAN="$(ip route get 1.1.1.1 2>/dev/null |
  awk '{for(i=1;i<=NF;i++)if($i=="src"){print $(i+1);exit}}')"

NOW="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

# Certification is created ONLY after every required gate passes.
cat > "$C/OMEGA_CERTIFIED.txt" <<CERT
OMEGA® FINAL CERTIFICATION
===========================
PROJECT: omega
VERSION: $(node -p "require('./package.json').version")
CERTIFIED: $NOW

FILESYSTEM: PASS
PACKAGE: PASS
CLI: PASS
PRODUCTION_BUILD: PASS
TESTS: PASS
SERVER: PASS
HTTP: 200
HTML: PASS

STATUS: OMEGA® CERTIFIED
CERT

cat > "$C/RUNTIME_STATE.txt" <<STATE
OMEGA® RUNTIME
==============
STATUS: RUNNING
PID: $PID
LOCAL: http://127.0.0.1:3000
LAN: ${LAN:+http://$LAN:3000}
HTTP: 200
CERTIFICATION: PASS
TIME: $NOW
STATE

echo
echo "OMEGA® CERTIFIED + RUNNING"
echo "BUILD PASS | TEST PASS | CLI PASS | HTTP 200"
echo "PID $PID | http://127.0.0.1:3000"
echo "CERT $C/OMEGA_CERTIFIED.txt"
