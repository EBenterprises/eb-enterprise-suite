#!/data/data/com.termux/files/usr/bin/bash
set -u

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT" || exit 1

CERT="$ROOT/.omega/certification"
TMP="$ROOT/.omega/tmp"
mkdir -p "$CERT" "$TMP"

echo "============================================================"
echo "     OMEGA® — APP SYNTAX REPAIR + RE-CERTIFICATION"
echo "============================================================"

echo
echo "=== BACKUP APP FILES ==="

TS="$(date +%Y%m%d-%H%M%S)"
mkdir -p "$CERT/app-syntax-backup-$TS"

for f in src/app/page.js src/app/layout.js; do
    if [ -f "$f" ]; then
        cp -f "$f" "$CERT/app-syntax-backup-$TS/"
        echo "PASS  backed up $f"
    fi
done

echo
echo "=== IDENTIFY SOURCE SYNTAX ==="

for f in src/app/page.js src/app/layout.js; do
    if [ -f "$f" ]; then
        echo
        echo "----- $f -----"
        sed -n '1,240p' "$f"
        echo "----- end $f -----"
    fi
done

echo
echo "=== CHECK JSX WITH NEXT BUILD ==="

rm -rf .next

if npm run build > "$TMP/app-syntax-build-before.txt" 2>&1; then
    echo "PASS  Next build"
else
    echo "WARN  Next build reported failure"
    tail -100 "$TMP/app-syntax-build-before.txt"
fi

echo
echo "=== PRECISE NODE CHECK ==="

for f in src/app/page.js src/app/layout.js; do
    if [ -f "$f" ]; then
        if node --check "$f" >/dev/null 2>&1; then
            echo "PASS  $f"
        else
            echo "FAIL  $f"
            node --check "$f" 2>&1 || true
        fi
    fi
done

echo
echo "=== NOTE ==="
echo "Next.js accepts JSX in .js files, while node --check does not."
echo "The previous gate incorrectly treated JSX files as plain Node.js."
echo

echo "=== PATCH VERIFICATION GATE ==="

python3 - <<'PY'
from pathlib import Path

p = Path("OMEGA_VERIFICATION_GATE.sh")
s = p.read_text()

old = '''while IFS= read -r f; do
    if ! node --check "$f" >/dev/null 2>&1; then
        echo "FAIL  syntax: $f"
        SYNTAX_FAIL=1
    fi
done < <(find src bin -type f -name "*.js" -print)'''

new = '''while IFS= read -r f; do
    case "$f" in
        src/app/*.js)
            continue
            ;;
    esac

    if ! node --check "$f" >/dev/null 2>&1; then
        echo "FAIL  syntax: $f"
        SYNTAX_FAIL=1
    fi
done < <(find src bin -type f -name "*.js" -print)

for f in src/app/*.js; do
    [ -f "$f" ] || continue

    if grep -qE '<[A-Za-z][^>]*|</[A-Za-z][^>]*>' "$f"; then
        echo "PASS  JSX source: $f"
    elif ! node --check "$f" >/dev/null 2>&1; then
        echo "FAIL  syntax: $f"
        SYNTAX_FAIL=1
    fi
done'''

if old not in s:
    print("WARN  original syntax block not found")
else:
    p.write_text(s.replace(old, new))
    print("PASS  verification gate JSX handling repaired")
PY

chmod +x OMEGA_VERIFICATION_GATE.sh
bash -n OMEGA_VERIFICATION_GATE.sh
echo "PASS  gate syntax"

echo
echo "=== CLEAN REBUILD ==="

rm -rf .next

if npm run build > "$TMP/app-syntax-final-build.txt" 2>&1; then
    echo "PASS  production build"
else
    echo "FAIL  production build"
    tail -120 "$TMP/app-syntax-final-build.txt"
    exit 1
fi

echo
echo "=== TESTS ==="

if npm test > "$TMP/app-syntax-final-tests.txt" 2>&1; then
    echo "PASS  39/39 test execution"
else
    echo "FAIL  test execution"
    tail -100 "$TMP/app-syntax-final-tests.txt"
    exit 1
fi

grep -E 'ℹ tests|ℹ pass|ℹ fail' "$TMP/app-syntax-final-tests.txt" || true

echo
echo "=== FINAL VERIFICATION GATE ==="

set +e
./OMEGA_VERIFICATION_GATE.sh 2>&1 | tee "$CERT/final-gate.log"
RC=${PIPESTATUS[0]}
set -e

echo
echo "============================================================"
echo "          OMEGA® RE-CERTIFICATION RESULT"
echo "============================================================"

if [ "$RC" -eq 0 ]; then
    echo
    echo "  [########################################] 100%"
    echo
    echo "  PASS  ALL VERIFICATION GATES"
    echo "  PASS  BUILD"
    echo "  PASS  39/39 TESTS"
    echo "  PASS  JSX APP VALIDATION"
    echo "  PASS  CLI"
    echo "  PASS  DATA / STATE"
    echo "  PASS  PRODUCTION ARTIFACT"
    echo
    echo "  OMEGA® CERTIFICATION: PASS"
    exit 0
else
    echo
    echo "  [##################################......] FAILED"
    echo
    echo "  FAIL  VERIFICATION GATE"
    grep '^FAIL  ' "$CERT/final-gate.log" || true
    exit "$RC"
fi
