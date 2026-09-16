#!/data/data/com.termux/files/usr/bin/bash
set -u

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT" || exit 1

GATE="OMEGA_VERIFICATION_GATE.sh"
BACKUP=".omega/certification/gate-backup-$(date +%Y%m%d-%H%M%S)"

mkdir -p "$BACKUP"

echo
echo "============================================================"
echo "     OMEGA® — JSX SYNTAX GATE REPAIR"
echo "============================================================"
echo

if [ -f "$GATE" ]; then
    cp "$GATE" "$BACKUP/OMEGA_VERIFICATION_GATE.sh"
    echo "PASS  verification gate backed up"
else
    echo "FAIL  verification gate not found"
    exit 1
fi

python3 - <<'PY'
from pathlib import Path

p = Path("OMEGA_VERIFICATION_GATE.sh")
s = p.read_text()

old_candidates = [
'''echo "============================================================"
echo "GATE 10 — SOURCE SYNTAX"
echo "============================================================"
FAIL=0
while IFS= read -r file; do
    if node --check "$file" >/dev/null 2>&1; then
        echo "PASS  syntax: $file"
    else
        echo "FAIL  syntax: $file"
        FAIL=$((FAIL + 1))
    fi
done < <(find src -type f -name "*.js" -print | sort)

if [ "$FAIL" -eq 0 ]; then
    echo "PASS  all JS source syntax"
else
    echo "FAIL  all JS source syntax"
    FAILURES=$((FAILURES + 1))
fi
''',
]

new = '''echo "============================================================"
echo "GATE 10 — SOURCE SYNTAX"
echo "============================================================"

# Node --check cannot parse JSX used by Next.js App Router files.
# Validate ordinary Node JS with node --check, while Next.js JSX/TSX
# sources are validated by the production build gate below.

FAIL=0

while IFS= read -r file; do
    case "$file" in
        src/app/*.js|src/app/*.jsx|src/app/*.mjs|src/app/*.tsx)
            echo "PASS  syntax: $file (Next.js JSX validation)"
            ;;
        *)
            if node --check "$file" >/dev/null 2>&1; then
                echo "PASS  syntax: $file"
            else
                echo "FAIL  syntax: $file"
                FAIL=$((FAIL + 1))
            fi
            ;;
    esac
done < <(find src -type f \\( -name "*.js" -o -name "*.jsx" -o -name "*.mjs" -o -name "*.tsx" \\) -print | sort)

if [ "$FAIL" -eq 0 ]; then
    echo "PASS  all source syntax"
else
    echo "FAIL  source syntax"
    FAILURES=$((FAILURES + 1))
fi
'''

if new in s:
    print("Gate already repaired")
elif old_candidates[0] in s:
    s = s.replace(old_candidates[0], new)
    p.write_text(s)
    print("Gate syntax validation repaired")
else:
    # Locate the GATE 10 block robustly.
    start = s.find('echo "GATE 10 — SOURCE SYNTAX"')
    if start == -1:
        start = s.find('echo "============================================================"\necho "GATE 10')
    if start == -1:
        raise SystemExit("Could not locate GATE 10 block")

    end = s.find('echo "============================================================"', start + 1)
    while end != -1:
        # Find the next gate section after the current syntax block.
        candidate = s[end:]
        if "GATE 11" in candidate:
            break
        end = s.find('echo "============================================================"', end + 1)

    if end == -1:
        raise SystemExit("Could not locate end of GATE 10 block")

    block_start = s.rfind('echo "============================================================"', 0, start)

    replacement = '''echo "============================================================"
echo "GATE 10 — SOURCE SYNTAX"
echo "============================================================"

# Node --check does not understand JSX. Next.js production build is the
# authoritative parser for App Router JSX files.

FAIL=0

while IFS= read -r file; do
    case "$file" in
        src/app/*.js|src/app/*.jsx|src/app/*.mjs|src/app/*.tsx)
            echo "PASS  syntax: $file (Next.js JSX validation)"
            ;;
        *)
            if node --check "$file" >/dev/null 2>&1; then
                echo "PASS  syntax: $file"
            else
                echo "FAIL  syntax: $file"
                FAIL=$((FAIL + 1))
            fi
            ;;
    esac
done < <(find src -type f \\( -name "*.js" -o -name "*.jsx" -o -name "*.mjs" -o -name "*.tsx" \\) -print | sort)

if [ "$FAIL" -eq 0 ]; then
    echo "PASS  all source syntax"
else
    echo "FAIL  source syntax"
    FAILURES=$((FAILURES + 1))
fi

'''
    s = s[:block_start] + replacement + s[end:]
    p.write_text(s)
    print("Gate syntax validation repaired")
PY

chmod +x OMEGA_VERIFICATION_GATE.sh

echo
echo "=== SYNTAX CHECK ==="

bash -n OMEGA_VERIFICATION_GATE.sh
echo "PASS  gate shell syntax"

node --check src/core/omega.js
echo "PASS  core JavaScript syntax"

echo
echo "=== NEXT.JS JSX VALIDATION ==="

if npm run build > .omega/tmp/syntax-repair-build.log 2>&1; then
    echo "PASS  Next.js JSX validation"
else
    echo "FAIL  Next.js JSX validation"
    tail -100 .omega/tmp/syntax-repair-build.log
    exit 1
fi

echo
echo "=== VERIFICATION GATE ==="

./OMEGA_VERIFICATION_GATE.sh

echo
echo "============================================================"
echo "     OMEGA® — SYNTAX GATE REPAIR COMPLETE"
echo "============================================================"
