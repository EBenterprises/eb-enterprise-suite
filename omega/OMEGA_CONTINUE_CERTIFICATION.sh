#!/data/data/com.termux/files/usr/bin/bash
set -u

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT" || exit 1

CERT="$ROOT/.omega/certification"
TMP="$ROOT/.omega/tmp"
GATE="$ROOT/OMEGA_VERIFICATION_GATE.sh"

mkdir -p "$CERT" "$TMP" public

TOTAL=12
STEP=0

progress() {
    STEP=$((STEP + 1))
    local width=40
    local filled=$((STEP * width / TOTAL))
    local empty=$((width - filled))
    printf "\r["
    printf "%${filled}s" "" | tr ' ' '#'
    printf "%${empty}s" "" | tr ' ' '.'
    printf "] %3d%%  %s" "$((STEP * 100 / TOTAL))" "$1"
    printf "\n"
}

run_step() {
    local label="$1"
    shift
    progress "$label"
    if "$@"; then
        echo "  PASS  $label"
    else
        echo "  FAIL  $label"
        return 1
    fi
}

echo
echo "============================================================"
echo "       OMEGA® — CERTIFICATION CONTINUATION"
echo "============================================================"
echo

run_step "Repair public directory" mkdir -p public

if [ -f src/app/favicon.ico ]; then
    progress "Repair favicon"
    cp -f src/app/favicon.ico public/favicon.ico
    rm -f src/app/favicon.ico
    echo "  PASS  favicon migrated"
elif [ -f public/favicon.ico ]; then
    progress "Verify favicon"
    echo "  PASS  public/favicon.ico already exists"
else
    progress "Create favicon placeholder"
    node <<'NODE'
const fs = require("fs");
const path = "public/favicon.ico";
const ico = Buffer.from(
  "AAABAAEAEBAAAAAAIABoBAAAFgAAACgAAAAQAAAAIAAAAAEABAAAAAAAgAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAA" +
  "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" +
  "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" +
  "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" +
  "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" +
  "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" +
  "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" +
  "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" +
  "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" +
  "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" +
  "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" +
  "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" +
  "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" +
  "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" +
  "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" +
  "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
  "base64"
);
fs.writeFileSync(path, ico);
NODE
    echo "  PASS  public/favicon.ico created"
fi

run_step "Validate favicon" test -f public/favicon.ico
run_step "Validate package.json" node -e 'JSON.parse(require("fs").readFileSync("package.json","utf8"))'
run_step "Validate package-lock.json" node -e 'JSON.parse(require("fs").readFileSync("package-lock.json","utf8"))'
run_step "Validate shell gate" bash -n "$GATE"

progress "Repair build configuration"
node <<'NODE'
const fs = require("fs");
const file = "package.json";
const pkg = JSON.parse(fs.readFileSync(file, "utf8"));
pkg.scripts ??= {};
pkg.scripts.build = "next build --webpack";
pkg.scripts.dev = "next dev --webpack";
fs.writeFileSync(file, JSON.stringify(pkg, null, 2) + "\n");
NODE
echo "  PASS  webpack configuration"

progress "Clean Next artifacts"
rm -rf .next
echo "  PASS  .next removed"

progress "Run production build"
if npm run build > "$TMP/continue-build.log" 2>&1; then
    echo "  PASS  production build"
else
    echo "  FAIL  production build"
    tail -80 "$TMP/continue-build.log"
    exit 1
fi

run_step "Verify .next artifact" test -d .next

progress "Run test suite"
if npm test > "$TMP/continue-tests.log" 2>&1; then
    echo "  PASS  npm test"
else
    echo "  FAIL  npm test"
    tail -80 "$TMP/continue-tests.log"
    exit 1
fi

tail -30 "$TMP/continue-tests.log"

progress "Run verification gate"
if [ ! -x "$GATE" ]; then
    chmod +x "$GATE"
fi

set +e
"$GATE" 2>&1 | tee "$CERT/continue-gate.log"
GATE_RC=${PIPESTATUS[0]}
set -e

if [ "$GATE_RC" -ne 0 ]; then
    echo
    echo "============================================================"
    echo "FAIL  VERIFICATION GATE"
    echo "============================================================"
    grep '^FAIL  ' "$CERT/continue-gate.log" || true
    exit "$GATE_RC"
fi

progress "Final CLI status"
if node bin/omega.js status; then
    echo "  PASS  CLI status"
else
    echo "  FAIL  CLI status"
    exit 1
fi

progress "Final capabilities"
if node bin/omega.js capabilities; then
    echo "  PASS  CLI capabilities"
else
    echo "  FAIL  CLI capabilities"
    exit 1
fi

echo
echo "============================================================"
echo "             OMEGA® FINAL CERTIFICATION"
echo "============================================================"
echo
echo "  [########################################] 100%"
echo
echo "  PASS  BUILD"
echo "  PASS  TESTS"
echo "  PASS  VERIFICATION"
echo "  PASS  CLI"
echo "  PASS  PRODUCTION ARTIFACT"
echo
echo "============================================================"
echo "       OMEGA® INITIALIZED • BUILT • VERIFIED"
echo "============================================================"
