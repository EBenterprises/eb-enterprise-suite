#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

CERT="$ROOT/.omega/certification"
TMP="$ROOT/.omega/tmp"
REPORT="$CERT/OMEGA_SOURCE_SYNTAX_AUDIT.txt"
ERRORS="$TMP/source-syntax-errors.txt"

mkdir -p "$CERT" "$TMP"

: > "$ERRORS"

echo "============================================================"
echo "        OMEGA® — SOURCE SYNTAX RESOLVER"
echo "============================================================"
echo
echo "Scanning source files..."
echo

FAILURES=0
CHECKED=0

check_js() {
    local file="$1"
    CHECKED=$((CHECKED + 1))

    if node --check "$file" >/dev/null 2>>"$ERRORS"; then
        echo "PASS  $file"
    else
        echo "FAIL  $file"
        FAILURES=$((FAILURES + 1))
        {
            echo
            echo "============================================================"
            echo "FILE: $file"
            echo "============================================================"
            node --check "$file" 2>&1 || true
        } >> "$ERRORS"
    fi
}

while IFS= read -r -d '' file; do
    check_js "$file"
done < <(
    find . \
        -type f \
        \( -name "*.js" -o -name "*.mjs" -o -name "*.cjs" \) \
        ! -path "./node_modules/*" \
        ! -path "./.next/*" \
        ! -path "./.git/*" \
        ! -path "./.omega/*" \
        -print0
)

echo
echo "============================================================"
echo "SCAN RESULT"
echo "============================================================"
echo "FILES CHECKED: $CHECKED"
echo "SYNTAX FAILURES: $FAILURES"
echo

{
    echo "============================================================"
    echo "OMEGA® SOURCE SYNTAX AUDIT"
    echo "============================================================"
    echo
    echo "FILES CHECKED: $CHECKED"
    echo "SYNTAX FAILURES: $FAILURES"
    echo
    cat "$ERRORS"
} | tee "$REPORT"

if [ "$FAILURES" -gt 0 ]; then
    echo
    echo "============================================================"
    echo "SOURCE SYNTAX ERROR(S) FOUND"
    echo "============================================================"
    echo
    echo "FULL ERROR REPORT:"
    echo "$ERRORS"
    echo
    echo "PASTE THE OUTPUT ABOVE BACK INTO CHAT."
    echo
    echo "OR RUN:"
    echo "cat \"$ERRORS\""
    echo
    echo "NO SOURCE FILES WERE MODIFIED."
    echo
    exit 1
fi

echo
echo "============================================================"
echo "OMEGA® SOURCE SYNTAX: PASS"
echo "============================================================"
echo
echo "ALL JAVASCRIPT SOURCE FILES PASSED."
echo
echo "REPORT:"
echo "$REPORT"
echo

exit 0
