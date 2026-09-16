#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
cd "$(dirname "$0")"

C=.omega/certification
T=.omega/tmp
P=.omega/production.pid
mkdir -p "$C" "$T"

TOTAL=15
STEP=0
FAIL_REASON=""

tick(){
  STEP=$((STEP+1))
  printf "\r[%02d/%02d] %-18s ✓" "$STEP" "$TOTAL" "$1"
}

fail(){
  FAIL_REASON="$1"
  printf "\r[%02d/%02d] %-18s ✗\n" "$STEP" "$TOTAL" "$FAIL_REASON"
  echo "STATUS: NOT CERTIFIED"
  exit 1
}

check(){
  "$@" >/dev/null 2>&1 || fail "$1"
}

echo
echo "OMEGA® FINAL VALIDATION"
echo

# 01
tick "filesystem"
for f in package.json package-lock.json bin/omega.js; do
  test -s "$f" || fail "$f"
done
for d in src tests public data; do
  test -d "$d" || fail "$d"
done

# 02
tick "package"
node - <<'NODE' || fail "package"
const fs=require("fs");
const p=JSON.parse(fs.readFileSync("package.json"));
const l=JSON.parse(fs.readFileSync("package-lock.json"));
if(p.name!=="omega")throw 0;
if(p.type!=="module")throw 0;
if(p.scripts?.build!=="next build --webpack")throw 0;
if(p.scripts?.dev!=="next dev --webpack")throw 0;
if(p.scripts?.start!=="next start")throw 0;
if(l.lockfileVersion!==3)throw 0;
NODE

# 03
tick "source"
while IFS= read -r -d '' f; do
  node --check "$f" >/dev/null 2>&1 || fail "$f"
done < <(
  find src -type f \
    \( -name '*.js' -o -name '*.mjs' \) \
    ! -path 'src/app/*' -print0
)

# 04
tick "next-app"
test -s src/app/page.js || fail "page.js"
test -s src/app/layout.js || fail "layout.js"

# 05
tick "config"
for f in next.config.mjs jsconfig.json postcss.config.mjs; do
  test -s "$f" || fail "$f"
done

# 06
tick "data"
node - <<'NODE' || fail "JSON"
const fs=require("fs");
for(const f of [
 "data/omega-memory.json",
 "data/omega-state.json",
 "data/versions.json"
])JSON.parse(fs.readFileSync(f));
NODE

# 07
tick "cli"
check node bin/omega.js status
check node bin/omega.js capabilities
check node bin/omega.js metrics

# 08
tick "build"
rm -rf .next
npm run build >"$T/build.log" 2>&1 || {
  tail -15 "$T/build.log"
  fail "build"
}
test -s .next/BUILD_ID || fail "BUILD_ID"

# 09
tick "artifacts"
test -d .next/server || fail ".next/server"
test -d .next/static || fail ".next/static"

# 10
tick "tests"
npm test >"$T/tests.log" 2>&1 || {
  tail -15 "$T/tests.log"
  fail "tests"
}

# 11
tick "server"
if test -s "$P"; then
  OLD="$(cat "$P" 2>/dev/null || true)"
  [ -z "$OLD" ] || kill "$OLD" 2>/dev/null || true
fi

nohup npm run start -- --hostname 0.0.0.0 \
  >"$T/server.log" 2>&1 &

PID=$!
echo "$PID" >"$P"

READY=0
for _ in $(seq 1 15); do
  if curl -fsS --max-time 1 \
      http://127.0.0.1:3000 >/dev/null 2>&1; then
    READY=1
    break
  fi
  kill -0 "$PID" 2>/dev/null || break
  sleep 1
done

[ "$READY" = 1 ] || {
  tail -15 "$T/server.log"
  fail "server"
}

# 12
tick "HTTP"
HTTP="$(
  curl -sS --max-time 3 \
    -o "$T/home.html" \
    -w '%{http_code}' \
    http://127.0.0.1:3000
)"
[ "$HTTP" = "200" ] || fail "HTTP-$HTTP"

# 13
tick "runtime"
kill -0 "$PID" 2>/dev/null || fail "PID"
grep -qi '<html' "$T/home.html" || fail "HTML"

# 14
tick "integrity"
test -s package.json || fail "package"
test -s package-lock.json || fail "lock"
test -s bin/omega.js || fail "CLI"
test -s .next/BUILD_ID || fail "BUILD"
test -s "$T/home.html" || fail "HTTP"

# 15
tick "certification"

NOW="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
VERSION="$(node -p "require('./package.json').version")"

cat >"$C/OMEGA_CERTIFIED.txt" <<CERT
OMEGA® FINAL CERTIFICATION
===========================
PROJECT: omega
VERSION: $VERSION
CERTIFIED: $NOW

FILESYSTEM: PASS
PACKAGE: PASS
SOURCE: PASS
NEXT_APP: PASS
CONFIGURATION: PASS
DATA: PASS
CLI: PASS
BUILD: PASS
ARTIFACTS: PASS
TESTS: PASS
SERVER: PASS
HTTP: PASS
RUNTIME: PASS
INTEGRITY: PASS

STATUS: OMEGA® CERTIFIED
CERT

cat >"$C/RUNTIME_STATE.txt" <<STATE
OMEGA® RUNTIME
==============
STATUS: RUNNING
PID: $PID
LOCAL: http://127.0.0.1:3000
HTTP: 200
CERTIFICATION: PASS
TIME: $NOW
STATE

printf "\n\n"
echo "████████████████████ 100%"
echo "OMEGA® CERTIFIED + RUNNING"
echo "PID: $PID"
echo "LOCAL: http://127.0.0.1:3000"
echo "CERT: $C/OMEGA_CERTIFIED.txt"
