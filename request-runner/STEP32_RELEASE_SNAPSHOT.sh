#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "=== EB PLATFORM® STEP 32 — RELEASE SNAPSHOT ==="

STAMP="$(date +%Y%m%d-%H%M%S)"
DEST=".backups/release-$STAMP"

mkdir -p "$DEST"

cp -f api/domain-service.js "$DEST/"
cp -f framework/lifecycle/canonical-lifecycle.js "$DEST/"
cp -f realtime-server.js "$DEST/"
cp -f package.json "$DEST/"
cp -f next.config.js "$DEST/" 2>/dev/null || true

for f in data/*.json; do
  cp -f "$f" "$DEST/"
done

printf '%s\n' "$STAMP" > "$DEST/RELEASE_TIMESTAMP"
printf '%s\n' "EB PLATFORM® RELEASE SNAPSHOT" > "$DEST/README"

echo "✓ Release snapshot created"
echo "✓ Source protected"
echo "✓ Persistence protected"
echo "✓ No live data modified"
echo
echo "=== STEP 32 COMPLETE ==="
