#!/data/data/com.termux/files/usr/bin/bash
set -u

cd "$(dirname "$0")" || exit 1

echo "============================================================"
echo "        OMEGA® REPAIR V10 — GATE NORMALIZATION"
echo "============================================================"

mkdir -p .omega/tmp
chmod 700 .omega .omega/tmp

echo
echo "[1/6] Installing required CSS build dependency..."

npm install @tailwindcss/postcss

echo
echo "[2/6] Normalizing ALL verification temp paths..."

python - <<'PY'
from pathlib import Path
import re

p = Path("OMEGA_VERIFICATION_GATE.sh")
s = p.read_text()

# Collapse any number of accidental repeated .omega prefixes.
s = re.sub(r'(?:\.omega)+/tmp/', '.omega/tmp/', s)

# Convert legacy absolute temp paths.
s = s.replace('/tmp/omega-gate-', '.omega/tmp/omega-gate-')
s = s.replace('/tmp/omega-test-output.txt', '.omega/tmp/omega-test-output.txt')
s = s.replace('/tmp/omega-next-build.txt', '.omega/tmp/omega-next-build.txt')

# Remove accidental repetitions again after replacements.
s = re.sub(r'(?:\.omega)+/tmp/', '.omega/tmp/', s)

p.write_text(s)
PY

echo "Remaining temp references:"
grep -nE 'omega-(gate|test|next)|\.omega\.omega|/tmp/omega-' \
    OMEGA_VERIFICATION_GATE.sh || true

echo
echo "[3/6] Fixing JSX-aware source verification..."

python - <<'PY'
from pathlib import Path

p = Path("OMEGA_VERIFICATION_GATE.sh")
s = p.read_text()

start = s.find('section "GATE 10 — SOURCE SYNTAX"')
end = s.find('section "GATE 11 — TEST DISCOVERY"')

if start == -1 or end == -1:
    raise SystemExit("Could not locate Gate 10 block")

replacement = '''section "GATE 10 — SOURCE SYNTAX"

SYNTAX_FAIL=0

# Node --check does not parse JSX. Next.js App Router files are
# validated by the Next build instead.
while IFS= read -r -d '' f; do
  case "$f" in
    src/app/page.js|src/app/layout.js)
      continue
      ;;
  esac

  if ! node --check "$f" >/dev/null 2>&1; then
    fail "syntax: $f"
    node --check "$f" 2>&1 | head -10
    SYNTAX_FAIL=1
  fi
done < <(find src bin -type f -name '*.js' -print0)

if [ "$SYNTAX_FAIL" -eq 0 ]; then
  pass "all non-JSX JS source syntax"
fi

'''

s = s[:start] + replacement + s[end:]
p.write_text(s)
PY

echo
echo "[4/6] Forcing Next production build to Webpack..."

python - <<'PY'
from pathlib import Path

p = Path("OMEGA_VERIFICATION_GATE.sh")
s = p.read_text()

# Replace the actual build invocation regardless of its current form.
s = s.replace('npm exec next build', 'npm exec next build -- --webpack')
s = s.replace('npx next build', 'npx next build --webpack')
s = s.replace('next build', 'next build --webpack')

# Avoid accidental duplicate flags.
s = s.replace('--webpack --webpack', '--webpack')

p.write_text(s)
PY

echo "Build command:"
grep -nE 'next build' OMEGA_VERIFICATION_GATE.sh || true

echo
echo "[5/6] Validating package state..."

node - <<'JS'
const p = require('./package.json');
console.log('next:', p.dependencies?.next);
console.log('react:', p.dependencies?.react);
console.log('react-dom:', p.dependencies?.['react-dom']);
console.log('@tailwindcss/postcss:', p.dependencies?.['@tailwindcss/postcss']);
console.log('build:', p.scripts?.build);
JS

echo
echo "[6/6] Direct functional verification..."

echo
echo "--- CLI ---"
for cmd in status capabilities metrics help; do
    echo ">>> omega $cmd"
    node bin/omega.js "$cmd" || exit 10
done

echo
echo "--- TESTS ---"
npm test || exit 11

echo
echo "--- WEBPACK BUILD ---"
npm run build || exit 12

echo
echo "============================================================"
echo "OMEGA® V10 DIRECT VERIFICATION: PASS"
echo "============================================================"
