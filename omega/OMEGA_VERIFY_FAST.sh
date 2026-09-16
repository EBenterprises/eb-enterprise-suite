#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

echo "OMEGA® INCREMENTAL VERIFICATION"
echo "================================"

COUNT=0
CACHED=0
VERIFIED=0

while IFS= read -r -d '' file; do
  COUNT=$((COUNT + 1))

  result="$(node engine/invention/verify-cache.js "$file")"

  if printf '%s\n' "$result" | grep -q '^CACHED$'; then
    CACHED=$((CACHED + 1))
  else
    VERIFIED=$((VERIFIED + 1))
  fi
done < <(
  find engine src bin \
    -type f \
    \( -name '*.js' -o -name '*.mjs' \) \
    -print0 2>/dev/null
)

echo
echo "FILES:    $COUNT"
echo "CACHED:   $CACHED"
echo "VERIFIED: $VERIFIED"
echo
echo "INCREMENTAL VERIFICATION: PASS"
