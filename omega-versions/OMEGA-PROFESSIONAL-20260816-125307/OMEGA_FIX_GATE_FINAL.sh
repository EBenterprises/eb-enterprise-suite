#!/data/data/com.termux/files/usr/bin/bash
set -u

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT" || exit 1

GATE="$ROOT/OMEGA_VERIFICATION_GATE.sh"
TMP="$ROOT/.omega/tmp"

mkdir -p "$TMP"
chmod 700 "$ROOT/.omega" "$TMP"

echo "============================================================"
echo "       OMEGA® FINAL VERIFICATION GATE REPAIR"
echo "============================================================"

node - "$GATE" <<'NODE'
const fs = require("fs");

const file = process.argv[2];
let s = fs.readFileSync(file, "utf8");

/*
 * Normalize every corrupted OMEGA temporary path.
 */
s = s.replace(/(?:\.omega)+\/tmp\//g, ".omega/tmp/");

/*
 * Normalize legacy absolute temporary paths.
 */
s = s.replace(/\/tmp\/omega-gate-/g, ".omega/tmp/omega-gate-");
s = s.replace(/\/tmp\/omega-test-output\.txt/g, ".omega/tmp/omega-test-output.txt");
s = s.replace(/\/tmp\/omega-next-build\.txt/g, ".omega/tmp/omega-next-build.txt");

/*
 * Make the Next production build explicitly Webpack-based.
 */
s = s.replace(
  /npm exec next build(?!\s+--webpack)/g,
  "npm exec next build -- --webpack"
);

/*
 * Ensure the gate creates its own Termux-safe workspace.
 */
const rootMarker = 'ROOT="$(cd "$(dirname "$0")" && pwd)"';

if (
  s.includes(rootMarker) &&
  !s.includes('mkdir -p "$ROOT/.omega/tmp"')
) {
  s = s.replace(
    rootMarker,
    `${rootMarker}
cd "$ROOT" || exit 1
mkdir -p "$ROOT/.omega/tmp"
chmod 700 "$ROOT/.omega" "$ROOT/.omega/tmp"`
  );
}

/*
 * Next.js .js files may contain JSX.
 * Node --check is therefore inappropriate for App Router files.
 */
const oldSyntax = `while IFS= read -r -d '' f; do
  if ! node --check "$f" >/dev/null 2>&1; then
    fail "syntax: $f"
    node --check "$f" 2>&1 | head -10
    SYNTAX_FAIL=1
  fi
done < <(find src bin -type f -name '*.js' -print0)`;

const newSyntax = `while IFS= read -r -d '' f; do
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
done < <(find src bin -type f -name '*.js' -print0)`;

if (s.includes(oldSyntax)) {
  s = s.replace(oldSyntax, newSyntax);
}

/*
 * Clean up any accidental repeated path components one final time.
 */
s = s.replace(/(?:\.omega)+\/tmp\//g, ".omega/tmp/");

fs.writeFileSync(file, s);
NODE

chmod +x "$GATE"

echo
echo "=== FINAL PATH AUDIT ==="
if grep -nE '\.omega\.omega|/tmp/omega-' "$GATE"; then
    echo "FAIL: corrupted paths remain"
    exit 1
else
    echo "PASS: no corrupted temporary paths"
fi

echo
echo "=== BUILD AUDIT ==="
grep -nE 'next build' "$GATE"

echo
echo "=== GATE SYNTAX ==="
bash -n "$GATE"
echo "PASS: gate shell syntax"

echo
echo "============================================================"
echo "FINAL GATE REPAIR: PASS"
echo "============================================================"
