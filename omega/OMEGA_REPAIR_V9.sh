#!/data/data/com.termux/files/usr/bin/bash
set -u

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT" || exit 1

echo "============================================================"
echo "          OMEGA® REPAIR V9 — ANDROID/ARM64"
echo "============================================================"

mkdir -p .omega/tmp
chmod 700 .omega .omega/tmp

echo
echo "[1/5] Repairing verification-gate paths..."

# Undo the accidental double-prefix introduced by the previous sed pass.
sed -i 's#\.omega\.omega/tmp/#.omega/tmp/#g' OMEGA_VERIFICATION_GATE.sh

# Ensure every OMEGA temporary artifact uses the project-local directory.
sed -i 's#/tmp/omega-gate-#.omega/tmp/omega-gate-#g' OMEGA_VERIFICATION_GATE.sh
sed -i 's#/tmp/omega-test-output\.txt#.omega/tmp/omega-test-output.txt#g' OMEGA_VERIFICATION_GATE.sh

echo "Gate temp references:"
grep -nE 'omega-(gate|test)|\.omega/tmp' OMEGA_VERIFICATION_GATE.sh || true

echo
echo "[2/5] Adding Android-safe Webpack configuration..."

cat > next.config.mjs <<'NEXTEOF'
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
};

export default nextConfig;
NEXTEOF

node -e '
const fs=require("fs");
const p=JSON.parse(fs.readFileSync("package.json","utf8"));
p.scripts=p.scripts||{};
p.scripts.build="next build --webpack";
p.scripts.dev="next dev --webpack";
fs.writeFileSync("package.json",JSON.stringify(p,null,2)+"\n");
'

npm install --package-lock-only >/dev/null 2>&1 || true

echo
echo "[3/5] Repairing JSX syntax verification..."

# Node's --check does not understand JSX in .js files.
# The files are valid Next.js source and must be excluded from raw Node syntax checks.
python - <<'PY'
from pathlib import Path

p = Path("OMEGA_VERIFICATION_GATE.sh")
s = p.read_text()

old = '''while IFS= read -r -d '' f; do
  if ! node --check "$f" >/dev/null 2>&1; then
    fail "syntax: $f"
    node --check "$f" 2>&1 | head -10
    SYNTAX_FAIL=1
  fi
done < <(find src bin -type f -name '*.js' -print0)'''

new = '''while IFS= read -r -d '' f; do
  case "$f" in
    src/app/page.js|src/app/layout.js)
      # Next.js App Router JSX source; raw node --check does not parse JSX.
      continue
      ;;
  esac

  if ! node --check "$f" >/dev/null 2>&1; then
    fail "syntax: $f"
    node --check "$f" 2>&1 | head -10
    SYNTAX_FAIL=1
  fi
done < <(find src bin -type f -name '*.js' -print0)'''

if old in s:
    s=s.replace(old,new)
else:
    print("NOTE: syntax block already changed or not found")

p.write_text(s)
PY

echo
echo "[4/5] Checking CLI directly..."

for cmd in status capabilities metrics help; do
    echo
    echo "--- omega $cmd ---"
    node bin/omega.js "$cmd"
    rc=$?
    if [ "$rc" -ne 0 ]; then
        echo "CLI FAILURE: $cmd (exit $rc)"
        exit "$rc"
    fi
done

echo
echo "[5/5] Running tests..."

npm test
TEST_RC=$?

if [ "$TEST_RC" -ne 0 ]; then
    echo
    echo "============================================================"
    echo "OMEGA® TESTS FAILED — STOPPING BEFORE BUILD"
    echo "EXIT: $TEST_RC"
    echo "============================================================"
    exit "$TEST_RC"
fi

echo
echo "============================================================"
echo "BUILDING OMEGA® WITH WEBPACK"
echo "============================================================"

npm run build
BUILD_RC=$?

echo
echo "============================================================"
if [ "$BUILD_RC" -eq 0 ]; then
    echo "OMEGA® REPAIR V9 COMPLETE"
    echo "CLI:      PASS"
    echo "TESTS:    PASS"
    echo "BUILD:    PASS"
else
    echo "OMEGA® BUILD STILL REQUIRES REPAIR"
    echo "BUILD EXIT: $BUILD_RC"
fi
echo "============================================================"

exit "$BUILD_RC"
