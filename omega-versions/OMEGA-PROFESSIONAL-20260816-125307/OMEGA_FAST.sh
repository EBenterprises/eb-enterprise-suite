#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
cd "$(dirname "$0")"

C=.omega/certification
T=.omega/tmp
P=.omega/production.pid
mkdir -p "$C" "$T"

FAIL(){ echo "FAIL:$1"; exit 1; }
OK(){ echo "PASS:$1"; }

echo "OMEGA® FAST"

# ---------- SOURCE / PACKAGE ----------
node -e '
const fs=require("fs");
const p=JSON.parse(fs.readFileSync("package.json"));
p.scripts=p.scripts||{};
p.scripts.start="next start";
p.scripts.build="next build --webpack";
p.scripts.dev="next dev --webpack";
fs.writeFileSync("package.json",JSON.stringify(p,null,2)+"\n");
' || FAIL package

for f in package.json package-lock.json bin/omega.js; do
  test -s "$f" || FAIL "$f"
done

for d in src/app tests public data; do
  test -d "$d" || FAIL "$d"
done

OK "FILES"

# ---------- CLI ----------
node bin/omega.js status >/dev/null 2>&1 || FAIL CLI
node bin/omega.js capabilities >/dev/null 2>&1 || FAIL CAPABILITIES
node bin/omega.js metrics >/dev/null 2>&1 || FAIL METRICS
OK "CLI"

# ---------- BUILD CACHE ----------
BUILD_STAMP=.omega/build-source.sha

HASH="$(
  find src public data \
    -type f \
    \( -name '*.js' -o -name '*.mjs' -o -name '*.json' -o -name '*.css' -o -name '*.tsx' -o -name '*.jsx' \) \
    -print0 2>/dev/null |
  sort -z |
  xargs -0 sha256sum 2>/dev/null |
  sha256sum |
  cut -d' ' -f1
)"

OLD="$(cat "$BUILD_STAMP" 2>/dev/null || true)"

if [ "$HASH" = "$OLD" ] &&
   test -s .next/BUILD_ID &&
   test -d .next/server; then
  OK "BUILD-CACHE"
else
  echo "$HASH" > "$BUILD_STAMP"
  rm -rf .next
  npm run build >/dev/null 2>&1 || FAIL BUILD
  test -s .next/BUILD_ID || FAIL BUILD_ID
  OK "BUILD"
fi

# ---------- TEST CACHE ----------
TEST_STAMP=.omega/test.sha
TEST_HASH="$(
  find src tests bin \
    -type f \
    \( -name '*.js' -o -name '*.mjs' \) \
    -print0 2>/dev/null |
  sort -z |
  xargs -0 sha256sum 2>/dev/null |
  sha256sum |
  cut -d' ' -f1
)"
OLD_TEST="$(cat "$TEST_STAMP" 2>/dev/null || true)"

if [ "$TEST_HASH" = "$OLD_TEST" ] &&
   test -f .omega/tests.pass; then
  OK "TEST-CACHE"
else
  npm test >/dev/null 2>&1 || FAIL TESTS
  echo "$TEST_HASH" > "$TEST_STAMP"
  touch .omega/tests.pass
  OK "TESTS"
fi

# ---------- SERVER ----------
if test -s "$P"; then
  PID="$(cat "$P" 2>/dev/null || true)"
else
  PID=""
fi

if [ -n "$PID" ] &&
   kill -0 "$PID" 2>/dev/null &&
   curl -fsS --max-time 2 http://127.0.0.1:3000 >/dev/null 2>&1; then
  OK "SERVER-CACHED"
else
  [ -n "$PID" ] && kill "$PID" 2>/dev/null || true
  rm -f "$P"

  nohup npm run start -- --hostname 0.0.0.0 \
    >"$T/server.log" 2>&1 &

  PID=$!
  echo "$PID" > "$P"

  READY=0
  for _ in $(seq 1 15); do
    if curl -fsS --max-time 1 http://127.0.0.1:3000 >/dev/null 2>&1; then
      READY=1
      break
    fi
    kill -0 "$PID" 2>/dev/null || break
    sleep 1
  done

  [ "$READY" = 1 ] || {
    echo "SERVER LOG:"
    tail -20 "$T/server.log" 2>/dev/null
    FAIL SERVER
  }

  OK "SERVER"
fi

# ---------- LIVE ----------
HTTP="$(
  curl -sS --max-time 3 \
    -o "$T/home.html" \
    -w '%{http_code}' \
    http://127.0.0.1:3000
)"

[ "$HTTP" = 200 ] || FAIL "HTTP-$HTTP"
grep -qi '<html' "$T/home.html" || FAIL HTML
OK "HTTP-200"

# ---------- CERTIFY ----------
NOW="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
VERSION="$(node -p "require('./package.json').version")"

cat > "$C/OMEGA_CERTIFIED.txt" <<CERT
OMEGA® FINAL CERTIFICATION
===========================
PROJECT: omega
VERSION: $VERSION
CERTIFIED: $NOW

FILES: PASS
CLI: PASS
BUILD: PASS
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
HTTP: 200
CERTIFICATION: PASS
TIME: $NOW
STATE

echo
echo "=============================="
echo "OMEGA® CERTIFIED"
echo "BUILD PASS | TEST PASS"
echo "SERVER PASS | HTTP 200"
echo "PID:$PID"
echo "http://127.0.0.1:3000"
echo "=============================="
