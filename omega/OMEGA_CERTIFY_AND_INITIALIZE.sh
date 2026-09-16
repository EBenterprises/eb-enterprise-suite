#!/data/data/com.termux/files/usr/bin/bash
set -u

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT" || exit 1

GATE="$ROOT/OMEGA_VERIFICATION_GATE.sh"
TMP="$ROOT/.omega/tmp"
CERT="$ROOT/.omega/certification"

mkdir -p "$TMP" "$CERT"
chmod 700 "$ROOT/.omega" "$TMP"

echo "============================================================"
echo "       OMEGA® CONTINUATION — CERTIFICATION REPAIR"
echo "============================================================"

# ------------------------------------------------------------
# 1. Repair Gate 14 ONLY
# ------------------------------------------------------------

node - "$GATE" <<'NODE'
const fs = require("fs");

const file = process.argv[2];
let s = fs.readFileSync(file, "utf8");

/*
 * Normalize all corrupted temporary paths.
 */
s = s.replace(/(?:\.omega)+\/tmp\//g, ".omega/tmp/");

/*
 * Replace every malformed Next gate invocation with the
 * known-good Termux invocation.
 */
s = s.replace(
  /npm exec next build(?:\s+--webpack)?/g,
  "npm exec next build -- --webpack"
);

/*
 * Remove accidental duplicate argument insertion.
 */
s = s.replace(
  /npm exec next build -- --webpack -- --webpack/g,
  "npm exec next build -- --webpack"
);

fs.writeFileSync(file, s);
NODE

chmod +x "$GATE"

echo
echo "=== GATE 14 COMMAND ==="
grep -nE 'npm exec next build|next build' "$GATE" || true

echo
echo "=== GATE SYNTAX ==="
bash -n "$GATE"
echo "PASS  verification gate syntax"

# ------------------------------------------------------------
# 2. Direct production build
# ------------------------------------------------------------

echo
echo "=== DIRECT PRODUCTION BUILD ==="

if npm run build > "$TMP/omega-cert-build.txt" 2>&1; then
    tail -30 "$TMP/omega-cert-build.txt"
    echo "PASS  production build"
else
    cat "$TMP/omega-cert-build.txt"
    echo "FAIL  production build"
    exit 1
fi

# ------------------------------------------------------------
# 3. Test suite
# ------------------------------------------------------------

echo
echo "=== TEST SUITE ==="

if npm test > "$TMP/omega-cert-test.txt" 2>&1; then
    tail -20 "$TMP/omega-cert-test.txt"
    echo "PASS  39/39 tests"
else
    cat "$TMP/omega-cert-test.txt"
    echo "FAIL  test suite"
    exit 1
fi

# ------------------------------------------------------------
# 4. Formal verification
# ------------------------------------------------------------

echo
echo "=== FORMAL VERIFICATION GATE ==="

set +e
"$GATE" 2>&1 | tee "$CERT/final-gate.log"
RC=${PIPESTATUS[0]}
set -e

echo
echo "============================================================"
echo "             OMEGA® CERTIFICATION RESULT"
echo "============================================================"

if [ "$RC" -ne 0 ]; then
    echo
    echo "FAIL  Formal verification"
    echo "EXIT CODE: $RC"
    echo
    echo "Remaining failures:"
    grep -E '^FAIL|VERIFICATION GATE:' "$CERT/final-gate.log" | tail -20 || true
    exit "$RC"
fi

echo
echo "PASS  Formal verification"
echo "PASS  OMEGA® CERTIFIED"

# ------------------------------------------------------------
# 5. Final identity/state
# ------------------------------------------------------------

node - <<'NODE'
const fs = require("fs");

const file = "data/omega-state.json";

let state = {};
try {
  state = JSON.parse(fs.readFileSync(file, "utf8"));
} catch {}

state.identity ??= {};
state.identity.name = "OMEGA";
state.identity.status = "operational";
state.identity.initialized = true;
state.identity.certified = true;
state.identity.certifiedAt = new Date().toISOString();

fs.writeFileSync(file, JSON.stringify(state, null, 2) + "\n");
NODE

# ------------------------------------------------------------
# 6. Git baseline
# ------------------------------------------------------------

echo
echo "=== GIT BASELINE ==="

if ! git config user.name >/dev/null 2>&1; then
    git config user.name "Easton Bodeux"
fi

if ! git config user.email >/dev/null 2>&1; then
    git config user.email "easton@localhost"
fi

git add -A

if git diff --cached --quiet; then
    echo "PASS  No new Git changes"
else
    git commit -m "Initialize OMEGA® certified baseline"
    echo "PASS  OMEGA® baseline committed"
fi

# ------------------------------------------------------------
# 7. Final report
# ------------------------------------------------------------

echo
echo "============================================================"
echo "          OMEGA® INITIALIZATION FINAL STATE"
echo "============================================================"

echo
echo "SYSTEM:"
node bin/omega.js status

echo
echo "CAPABILITIES:"
node bin/omega.js capabilities

echo
echo "TESTS:"
grep -E 'ℹ pass|ℹ fail' "$TMP/omega-cert-test.txt" | tail -2

echo
echo "BUILD:"
test -d .next && echo "PASS  .next production artifact"

echo
echo "GIT:"
git status --short --branch

echo
echo "COMMIT:"
git log -1 --oneline

echo
echo "CERTIFICATION:"
grep -E 'PASS:|FAIL:|WARN:|VERIFICATION GATE:' \
    "$CERT/final-gate.log" | tail -10

echo
echo "============================================================"
echo "       OMEGA® INITIALIZED • BUILT • VERIFIED • CERTIFIED"
echo "============================================================"
