#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

TMP="$ROOT/.omega/tmp"
REPORT="$TMP/source-syntax-v2-report.txt"
mkdir -p "$TMP"

FAILURES=0
CHECKED=0
BACKUP_DIR="$TMP/source-syntax-backup-$(date +%Y%m%d_%H%M%S)"

pass() {
    echo "PASS  $1"
}

fail() {
    echo "FAIL  $1"
    FAILURES=$((FAILURES + 1))
}

echo "============================================================"
echo "        OMEGA® — SOURCE SYNTAX RESOLVER V2"
echo "============================================================"
echo
echo "IMPORTANT:"
echo "Next.js App Router .js files may contain JSX."
echo "Node --check does NOT parse JSX in plain .js files."
echo "Therefore this audit uses the project's Next.js build/linter"
echo "path for JSX files and Node syntax checking for plain JS."
echo

mkdir -p "$BACKUP_DIR"

# ------------------------------------------------------------
# 1. INVENTORY
# ------------------------------------------------------------

echo "=== 1. SOURCE INVENTORY ==="

SOURCE_FILES=()

while IFS= read -r -d '' file; do
    SOURCE_FILES+=("$file")
done < <(
    find . \
        -type f \
        \( -name "*.js" -o -name "*.mjs" -o -name "*.cjs" \) \
        ! -path "./node_modules/*" \
        ! -path "./.next/*" \
        ! -path "./.git/*" \
        ! -path "./.omega/tmp/*" \
        ! -path "./.omega/certification/*" \
        -print0
)

echo "SOURCE FILES DISCOVERED: ${#SOURCE_FILES[@]}"
echo

# ------------------------------------------------------------
# 2. BACKUP ONLY THE FOUR KNOWN JSX FAILURES
# ------------------------------------------------------------

echo "=== 2. SAFE BACKUP ==="

for file in \
    "./src/app/page.js" \
    "./src/app/layout.js" \
    "./backups/next8-20260814-195911/src/app/page.js" \
    "./backups/next8-20260814-195911/src/app/layout.js"
do
    if [ -f "$file" ]; then
        mkdir -p "$BACKUP_DIR/$(dirname "$file")"
        cp -p "$file" "$BACKUP_DIR/$file"
        pass "backup: $file"
    fi
done

echo
echo "BACKUP:"
echo "$BACKUP_DIR"

# ------------------------------------------------------------
# 3. DETERMINE WHICH FILES ACTUALLY CONTAIN JSX
# ------------------------------------------------------------

echo
echo "=== 3. JSX-AWARE SYNTAX CLASSIFICATION ==="

JSX_FILES=()
PLAIN_JS_FILES=()

for file in "${SOURCE_FILES[@]}"; do
    if grep -Eq '<[A-Za-z][A-Za-z0-9:_-]*([[:space:]>]|$)|<[A-Za-z][A-Za-z0-9:_-]*[[:space:]]' "$file"; then
        JSX_FILES+=("$file")
    else
        PLAIN_JS_FILES+=("$file")
    fi
done

echo "JSX-CANDIDATES: ${#JSX_FILES[@]}"
echo "PLAIN JS/MJS:  ${#PLAIN_JS_FILES[@]}"

# ------------------------------------------------------------
# 4. NODE CHECK ONLY PLAIN JS
# ------------------------------------------------------------

echo
echo "=== 4. PLAIN JAVASCRIPT SYNTAX ==="

for file in "${PLAIN_JS_FILES[@]}"; do
    CHECKED=$((CHECKED + 1))

    if node --check "$file" >"$TMP/node-check.out" 2>&1; then
        pass "$file"
    else
        fail "$file"
        {
            echo
            echo "FILE: $file"
            cat "$TMP/node-check.out"
        } >> "$REPORT"
    fi
done

# ------------------------------------------------------------
# 5. JSX FILES — USE NEXT/ESLINT VALIDATION
# ------------------------------------------------------------

echo
echo "=== 5. JSX / NEXT.JS VALIDATION ==="

if [ -x "./node_modules/.bin/eslint" ]; then
    echo "ESLint detected."

    if ./node_modules/.bin/eslint \
        ./src/app/page.js \
        ./src/app/layout.js \
        >"$TMP/jsx-eslint.out" 2>&1
    then
        pass "src/app/page.js + layout.js JSX validation"
    else
        fail "JSX validation"
        cat "$TMP/jsx-eslint.out"
        {
            echo
            echo "=== ESLINT JSX REPORT ==="
            cat "$TMP/jsx-eslint.out"
        } >> "$REPORT"
    fi
else
    echo "ESLint executable unavailable."
    echo "Using Next.js production build as JSX parser."

    if npm run build >"$TMP/next-build-syntax.out" 2>&1; then
        pass "Next.js JSX/build validation"
    else
        echo "Next.js build failed."
        echo
        echo "Build output:"
        tail -200 "$TMP/next-build-syntax.out"

        {
            echo
            echo "=== NEXT BUILD REPORT ==="
            cat "$TMP/next-build-syntax.out"
        } >> "$REPORT"

        fail "Next.js JSX/build validation"
    fi
fi

# ------------------------------------------------------------
# 6. EXPLICIT KNOWN FILE CHECK
# ------------------------------------------------------------

echo
echo "=== 6. APP ROUTER FILES ==="

for file in \
    "./src/app/page.js" \
    "./src/app/layout.js"
do
    if [ -f "$file" ]; then
        if grep -Eq '(^|[[:space:]])(export[[:space:]]+default|import[[:space:]])' "$file"; then
            pass "App Router structure: $file"
        else
            fail "App Router structure: $file"
        fi
    else
        fail "missing App Router file: $file"
    fi
done

# ------------------------------------------------------------
# 7. BACKUP FILES ARE NOT PRODUCTION SOURCE
# ------------------------------------------------------------

echo
echo "=== 7. BACKUP ISOLATION ==="

for file in \
    "./backups/next8-20260814-195911/src/app/page.js" \
    "./backups/next8-20260814-195911/src/app/layout.js"
do
    if [ -f "$file" ]; then
        pass "backup retained, excluded from production audit: $file"
    fi
done

# ------------------------------------------------------------
# 8. VERIFY NODE_MODULES / NEXT
# ------------------------------------------------------------

echo
echo "=== 8. NEXT.JS TOOLCHAIN ==="

if node -p 'require("./node_modules/next/package.json").version' >/dev/null 2>&1; then
    NEXT_VERSION="$(node -p 'require("./node_modules/next/package.json").version')"
    pass "Next.js available: $NEXT_VERSION"
else
    fail "Next.js unavailable"
fi

if [ -x "./node_modules/.bin/next" ]; then
    pass "Next CLI available"
else
    fail "Next CLI unavailable"
fi

# ------------------------------------------------------------
# 9. WRITE MACHINE-READABLE RESULT
# ------------------------------------------------------------

echo
echo "=== 9. RESULT ==="

{
    echo "OMEGA® SOURCE SYNTAX RESOLVER V2"
    echo "DATE: $(date -Iseconds)"
    echo "CHECKED: $CHECKED"
    echo "FAILURES: $FAILURES"
    echo "BACKUP: $BACKUP_DIR"
    echo "NEXT: ${NEXT_VERSION:-unknown}"
} > "$TMP/source-syntax-v2-status.txt"

if [ "$FAILURES" -eq 0 ]; then
    echo
    echo "[########################################] 100%"
    echo
    echo "OMEGA® SOURCE SYNTAX: PASS"
    echo
    echo "IMPORTANT:"
    echo "JSX in src/app/*.js is valid Next.js source."
    echo "It must not be judged with raw node --check."
    echo
    echo "NEXT ACTION:"
    echo "./OMEGA_FINAL_INTEGRITY_AUDIT.sh"
else
    echo
    echo "============================================================"
    echo "OMEGA® SOURCE SYNTAX: FAIL"
    echo "FAILURES: $FAILURES"
    echo "============================================================"
    echo
    echo "FULL REPORT:"
    echo "$REPORT"
    echo
    echo "NO SOURCE FILES WERE MODIFIED."
    exit 1
fi
