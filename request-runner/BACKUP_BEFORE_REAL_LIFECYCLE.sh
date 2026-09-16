#!/data/data/com.termux/files/usr/bin/bash
set -e

ROOT="$HOME/request-runner"
BACKUP="$ROOT/.backups/pre-real-lifecycle-$(date +%Y%m%d-%H%M%S)"

mkdir -p "$BACKUP"

echo "=============================================================="
echo " EB PLATFORM® — PROTECTED BACKUP"
echo "=============================================================="
echo
echo "Backup: $BACKUP"
echo

cp -a "$ROOT/app" "$BACKUP/"
cp -a "$ROOT/api" "$BACKUP/"
cp -a "$ROOT/framework" "$BACKUP/"
cp -a "$ROOT/apps" "$BACKUP/"
cp -a "$ROOT/data" "$BACKUP/" 2>/dev/null || true
cp -a "$ROOT/server.js" "$BACKUP/" 2>/dev/null || true
cp -a "$ROOT/package.json" "$BACKUP/" 2>/dev/null || true
cp -a "$ROOT/next.config.js" "$BACKUP/" 2>/dev/null || true

echo "✓ Application source backed up"
echo "✓ API backed up"
echo "✓ Framework backed up"
echo "✓ Modules backed up"
echo "✓ Data backed up"
echo

du -sh "$BACKUP"

echo
echo "=============================================================="
echo " BACKUP COMPLETE"
echo "=============================================================="
echo "$BACKUP"
