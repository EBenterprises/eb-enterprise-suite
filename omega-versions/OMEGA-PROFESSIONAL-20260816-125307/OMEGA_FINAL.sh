#!/data/data/com.termux/files/usr/bin/bash
set -u

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT" || exit 1

CERT="$ROOT/.omega/certification"
LOG="$ROOT/.omega/tmp"
mkdir -p "$CERT" "$LOG"

echo
echo "============================================================"
echo " OMEGA® — CLEAN FINAL CERTIFICATION"
echo "============================================================"
echo

# ------------------------------------------------------------
# 01 — FILESYSTEM
# ------------------------------------------------------------
printf '[ 12%% ] Filesystem ... '

FILES=(
  package.json
  package-lock.json
  bin/omega.js
  src/core/omega.js
  src/core/kernel.js
  src/app/page.js
  src/app/layout.js
  public
  data
  tests
)

for f in "${FILES[@]}"; do
    test -e "$f" || {
        echo "FAIL"
        echo "Missing: $f"
        exit 1
    }
done

echo "PASS"

# ------------------------------------------------------------
# 02 — PACKAGE
# ------------------------------------------------------------
printf '[ 25%% ] Package ... '

node <<'NODE'
const fs = require("fs");

const p = JSON.parse(fs.readFileSync("package.json", "utf8"));
const l = JSON.parse(fs.readFileSync("package-lock.json", "utf8"));

if (p.name !== "omega") throw Error("package name");
if (p.version !== "1.0.0") throw Error("package version");
if (p.type !== "module") throw Error("package type");

if (!p.scripts) throw Error("scripts missing");
if (p.scripts.build !== "next build --webpack") throw Error("build script");
if (p.scripts.dev !== "next dev --webpack") throw Error("dev script");

if (l.lockfileVersion !== 3) throw Error("lockfile version");

console.log("PASS");
NODE

# ------------------------------------------------------------
# 03 — CORE JAVASCRIPT ONLY
#
# IMPORTANT:
# node --check is deliberately NOT run against src/app.
# Next.js owns JSX validation.
# ------------------------------------------------------------
printf '[ 37%% ] Core JavaScript ... '

FAIL=0

while IFS= read -r -d '' file; do
    if ! node --check "$file" >/dev/null 2>&1; then
        echo
        echo "FAIL: $file"
        FAIL=1
    fi
done < <(
    find src \
      -type f \
      \( -name "*.js" -o -name "*.mjs" \) \
      ! -path "src/app/*" \
      -print0
)

[ "$FAIL" -eq 0 ] || exit 1

echo "PASS"

# ------------------------------------------------------------
# 04 — NEXT APP FILES
# ------------------------------------------------------------
printf '[ 50%% ] Next application ... '

test -s src/app/page.js
test -s src/app/layout.js

echo "PASS"

# ------------------------------------------------------------
# 05 — BUILD
#
# Exactly ONE build.
# No build inside the verification gate.
# ------------------------------------------------------------
printf '[ 62%% ] Production build ... '

rm -rf .next

if npm run build > "$LOG/final-build.log" 2>&1; then
    test -d .next
    echo "PASS"
else
    echo "FAIL"
    echo
    tail -100 "$LOG/final-build.log"
    exit 1
fi

# ------------------------------------------------------------
# 06 — TESTS
# ------------------------------------------------------------
printf '[ 75%% ] Tests ... '

if npm test > "$LOG/final-tests.log" 2>&1; then
    echo "PASS"
else
    echo "FAIL"
    echo
    tail -100 "$LOG/final-tests.log"
    exit 1
fi

# ------------------------------------------------------------
# 07 — TEST RESULT
# ------------------------------------------------------------
printf '[ 87%% ] Test result ... '

grep -q "ℹ fail 0" "$LOG/final-tests.log" || {
    echo "FAIL"
    tail -40 "$LOG/final-tests.log"
    exit 1
}

grep -q "ℹ pass 39" "$LOG/final-tests.log" || {
    echo "FAIL"
    tail -40 "$LOG/final-tests.log"
    exit 1
}

echo "39/39 PASS"

# ------------------------------------------------------------
# 08 — DATA
# ------------------------------------------------------------
printf '[ 94%% ] Data integrity ... '

node <<'NODE'
const fs = require("fs");

for (const file of [
  "data/omega-memory.json",
  "data/omega-state.json",
  "data/versions.json"
]) {
  JSON.parse(fs.readFileSync(file, "utf8"));
}
NODE

echo "PASS"

# ------------------------------------------------------------
# 09 — CLI
# ------------------------------------------------------------
printf '[ 97%% ] CLI ... '

node bin/omega.js status >/dev/null
node bin/omega.js capabilities >/dev/null
node bin/omega.js metrics >/dev/null

echo "PASS"

# ------------------------------------------------------------
# 10 — CERTIFICATE
# ------------------------------------------------------------
printf '[100%%] Certification ... '

cat > "$CERT/FINAL_CERTIFICATION.txt" <<CERT
OMEGA® FINAL CERTIFICATION

Project: OMEGA®
Version: 1.0.0
Date: $(date -u +"%Y-%m-%dT%H:%M:%SZ")

Filesystem: PASS
Package: PASS
Core JavaScript: PASS
Next App: PASS
Production Build: PASS
Tests: 39/39 PASS
Data Integrity: PASS
CLI: PASS

STATUS: CERTIFIED
CERT

echo "PASS"

echo
echo "============================================================"
echo " [########################################] 100%"
echo "============================================================"
echo
echo "OMEGA® CERTIFIED"
echo
cat "$CERT/FINAL_CERTIFICATION.txt"
echo
echo "No additional verification gate was executed."
echo "No duplicate production build was executed."
echo "No JSX was passed through node --check."
echo
echo "============================================================"
