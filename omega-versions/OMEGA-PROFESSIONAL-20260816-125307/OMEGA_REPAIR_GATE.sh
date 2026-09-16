#!/data/data/com.termux/files/usr/bin/bash
set -u

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT" || exit 1

TMP="$ROOT/.omega/tmp"
mkdir -p "$TMP"
chmod 700 "$TMP"

GATE="$ROOT/OMEGA_VERIFICATION_GATE.sh"

echo "============================================================"
echo "        OMEGA® VERIFICATION GATE REPAIR"
echo "============================================================"

# ------------------------------------------------------------
# 1. Normalize every corrupted temporary-path reference.
# ------------------------------------------------------------
echo "[1/5] Normalizing gate paths..."

python - "$GATE" <<'PY'
from pathlib import Path
import re
import sys

p = Path(sys.argv[1])
s = p.read_text()

# Collapse every corrupted .omega chain.
s = re.sub(r'\.omega(?:\.omega)+/tmp/', '.omega/tmp/', s)

# Convert any remaining absolute temporary OMEGA paths.
s = s.replace('/tmp/omega-gate-', '.omega/tmp/omega-gate-')
s = s.replace('/tmp/omega-test-output.txt', '.omega/tmp/omega-test-output.txt')
s = s.replace('/tmp/omega-next-build.txt', '.omega/tmp/omega-next-build.txt')

# Collapse accidental repeats again after replacements.
s = re.sub(r'\.omega(?:\.omega)+/tmp/', '.omega/tmp/', s)

p.write_text(s)
PY

# ------------------------------------------------------------
# 2. Make the gate itself Termux-safe.
# ------------------------------------------------------------
echo "[2/5] Repairing CLI/test temporary paths..."

python - "$GATE" <<'PY'
from pathlib import Path
import sys

p = Path(sys.argv[1])
s = p.read_text()

# Ensure the gate creates its workspace.
marker = 'ROOT="$(cd "$(dirname "$0")" && pwd)"'
if marker in s and 'mkdir -p "$ROOT/.omega/tmp"' not in s:
    s = s.replace(
        marker,
        marker + '\ncd "$ROOT" || exit 1\nmkdir -p "$ROOT/.omega/tmp"\nchmod 700 "$ROOT/.omega/tmp"'
    )

# Force Next production build through Webpack on Android/ARM64.
s = s.replace(
    'npm exec next build > .omega/tmp/omega-next-build.txt',
    'npm exec next build -- --webpack > .omega/tmp/omega-next-build.txt'
)

s = s.replace(
    'npm exec next build  > .omega/tmp/omega-next-build.txt',
    'npm exec next build -- --webpack  > .omega/tmp/omega-next-build.txt'
)

p.write_text(s)
PY

# ------------------------------------------------------------
# 3. Replace the invalid Node JSX syntax gate.
#    Next.js owns compilation of app/page.js and app/layout.js.
# ------------------------------------------------------------
echo "[3/5] Repairing JSX syntax verification..."

python - "$GATE" <<'PY'
from pathlib import Path
import sys

p = Path(sys.argv[1])
s = p.read_text()

old = '''while IFS= read -r -d '' f; do
  if ! node --check "$f" >/dev/null 2>&1; then
    fail "syntax: $f"
    node --check "$f" 2>&1 | head -10
    SYNTAX_FAIL=1
  fi
done < <(find src bin -type f -name '*.js' -print0)'''

new = '''while IFS= read -r -d '' f; do
  # Next.js app .js files may intentionally contain JSX.
  # They are validated by the Next production build instead of node --check.
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
done < <(find src bin -type f -name '*.js' -print0)'''

if old in s:
    s = s.replace(old, new)
else:
    print("NOTE: JSX syntax block already changed or differs; leaving it untouched.")

p.write_text(s)
PY

# ------------------------------------------------------------
# 4. Ensure package build uses Webpack.
# ------------------------------------------------------------
echo "[4/5] Ensuring package build is Android-safe..."

node - <<'JS'
const fs = require("fs");

const file = "package.json";
const pkg = JSON.parse(fs.readFileSync(file, "utf8"));

pkg.scripts ??= {};
pkg.scripts.build = "next build --webpack";
pkg.scripts.dev = "next dev --webpack";

fs.writeFileSync(file, JSON.stringify(pkg, null, 2) + "\n");
JS

npm install

# ------------------------------------------------------------
# 5. Verify that the gate no longer contains corruption.
# ------------------------------------------------------------
echo "[5/5] Gate integrity check..."

echo
echo "--- PATH CHECK ---"
grep -nE '\.omega\.omega|/tmp/omega-' "$GATE" || true

echo
echo "--- BUILD COMMAND CHECK ---"
grep -nE 'next build' "$GATE" || true

echo
echo "--- JSX CHECK ---"
grep -n -A8 -B3 'src/app/page.js|src/app/layout.js' "$GATE" || true

chmod +x "$GATE"

echo
echo "============================================================"
echo "GATE REPAIR COMPLETE"
echo "============================================================"
