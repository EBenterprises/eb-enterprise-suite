#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

cd ~/omega

CACHE=".omega/cache"
mkdir -p "$CACHE"

TOTAL=0
CACHED=0
CHECKED=0

printf '\nOMEGA® INCREMENTAL VERIFY\n'

while IFS= read -r -d '' file; do
    TOTAL=$((TOTAL + 1))

    HASH="$(sha256sum "$file" | awk '{print $1}')"
    PROOF="$CACHE/$HASH"

    if [ -f "$PROOF" ]; then
        CACHED=$((CACHED + 1))
        continue
    fi

    if node --check "$file" >/dev/null 2>&1; then
        printf '%s\n' "$file" > "$PROOF"
        CHECKED=$((CHECKED + 1))
    else
        printf 'FAIL: %s\n' "$file"
        exit 1
    fi
done < <(
    find engine bin src \
        -type f \
        \( -name '*.js' -o -name '*.mjs' \) \
        ! -path 'src/app/*' \
        -print0 2>/dev/null
)

printf 'FILES:   %s\n' "$TOTAL"
printf 'CACHED:  %s\n' "$CACHED"
printf 'CHECKED: %s\n' "$CHECKED"
printf 'STATUS:  PASS\n\n'
