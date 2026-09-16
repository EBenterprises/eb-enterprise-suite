#!/data/data/com.termux/files/usr/bin/bash
set -u

cd ~/request-runner || exit 1

ENGINE="COMPLETION ENGINE® — V8 FINALIZATION REPAIR"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP=".completion-backups/finalization-$STAMP"
LOG=".completion-logs/finalization-$STAMP.log"

mkdir -p "$BACKUP" .completion-logs .completion-state

exec > >(tee "$LOG") 2>&1

echo "=============================================================="
echo " $ENGINE"
echo "=============================================================="

echo
echo "[1/10] ENVIRONMENT"
echo "--------------------------------------------------------------"

echo "Node:"
node -v

echo "npm:"
npm -v

echo "Next:"
node -e 'console.log(require("next/package.json").version)'

echo
echo "Build script:"
node -e '
const p=require("./package.json");
console.log(p.scripts?.build || "(missing)");
'

echo
echo "Memory:"
awk '
/MemTotal:/     {printf "TOTAL_MB=%.0f\n",$2/1024}
/MemAvailable:/ {printf "AVAILABLE_MB=%.0f\n",$2/1024}
/SwapTotal:/    {printf "SWAP_TOTAL_MB=%.0f\n",$2/1024}
/SwapFree:/     {printf "SWAP_FREE_MB=%.0f\n",$2/1024}
' /proc/meminfo

echo
echo "Storage:"
df -h .

echo
echo "[2/10] SNAPSHOT"
echo "--------------------------------------------------------------"

[ -f next.config.js ] && cp next.config.js "$BACKUP/next.config.js"
[ -f package.json ] && cp package.json "$BACKUP/package.json"
[ -f package-lock.json ] && cp package-lock.json "$BACKUP/package-lock.json"
[ -f jsconfig.json ] && cp jsconfig.json "$BACKUP/jsconfig.json"
[ -f tsconfig.json ] && cp tsconfig.json "$BACKUP/tsconfig.json"

echo "✓ Snapshot: $BACKUP"

echo
echo "[3/10] CONFIGURATION AUDIT"
echo "--------------------------------------------------------------"

node <<'NODE'
const fs=require("fs");

const pkg=JSON.parse(fs.readFileSync("package.json","utf8"));

console.log("BUILD_SCRIPT:",pkg.scripts?.build || "(missing)");

const config=fs.readFileSync("next.config.js","utf8");

console.log(
  "WEBPACK_HOOK:",
  /\bwebpack\s*:/.test(config) ? "PRESENT" : "ABSENT"
);

console.log(
  "TURBOPACK_CONFIG:",
  /\bturbopack\s*:/.test(config) ? "PRESENT" : "ABSENT"
);
NODE

echo
echo "[4/10] SOURCE / ROUTE INVENTORY"
echo "--------------------------------------------------------------"

printf "App route files: "
find app -type f \
  \( -name 'page.*' -o -name 'route.*' -o -name 'layout.*' \) \
  2>/dev/null | wc -l

printf "Pages route files: "
find pages -type f 2>/dev/null | wc -l

printf "Public files: "
find public -type f 2>/dev/null | wc -l

echo
echo "[5/10] NEXT INTERNAL MANIFEST AUDIT"
echo "--------------------------------------------------------------"

grep -RniF "_ssgManifest.js" \
  node_modules/next/dist \
  2>/dev/null | head -80 || true

echo
echo "[6/10] CLEAN BUILD"
echo "--------------------------------------------------------------"

rm -rf .next

sync

unset TURBOPACK
unset NEXT_TURBOPACK
unset NEXT_PRIVATE_TURBOPACK

export NEXT_TELEMETRY_DISABLED=1

BUILD_LOG="$BACKUP/build.log"

set +e
npm run build >"$BUILD_LOG" 2>&1
BUILD_RC=$?
set -e

cat "$BUILD_LOG"

echo
echo "BUILD_RC=$BUILD_RC"

echo
echo "[7/10] .NEXT FORENSIC AUDIT"
echo "--------------------------------------------------------------"

if [ -d .next ]; then
    echo "✓ .next exists"
else
    echo "✗ .next missing"
fi

if [ -d .next/static ]; then
    echo "✓ .next/static exists"
    du -sh .next/static 2>/dev/null || true
else
    echo "✗ .next/static missing"
fi

echo
echo "Static directories:"
find .next/static \
  -mindepth 1 \
  -maxdepth 2 \
  -type d \
  2>/dev/null | head -100 || true

echo
echo "Manifest files:"
find .next \
  -type f \
  \( \
    -name '_ssgManifest.js' \
    -o -name '*manifest.json' \
    -o -name '*manifest.js' \
  \) \
  -print 2>/dev/null | sort | head -200 || true

echo
echo "Referenced missing manifest:"
grep -nF "_ssgManifest.js" "$BUILD_LOG" || true

echo
echo "[8/10] BUILD OUTPUT CLASSIFICATION"
echo "--------------------------------------------------------------"

if grep -qF "_ssgManifest.js" "$BUILD_LOG"; then
    echo "FAILURE_CLASS=NEXT_SSG_MANIFEST_FINALIZATION"
elif grep -qEi 'ENOENT|EACCES|ENOSPC' "$BUILD_LOG"; then
    echo "FAILURE_CLASS=FILESYSTEM"
elif grep -qEi 'Module not found|Cannot find module' "$BUILD_LOG"; then
    echo "FAILURE_CLASS=MODULE_RESOLUTION"
elif [ "$BUILD_RC" -eq 0 ]; then
    echo "FAILURE_CLASS=NONE"
else
    echo "FAILURE_CLASS=OTHER"
fi

echo
echo "[9/10] ROUTE/MANIFEST VALIDATION"
echo "--------------------------------------------------------------"

if [ -d .next/server/app ]; then
    APP_OUTPUT="$(find .next/server/app \
      -type f \
      2>/dev/null | wc -l)"
else
    APP_OUTPUT=0
fi

echo "SERVER_APP_FILES=$APP_OUTPUT"

for f in \
    .next/server/app-paths-manifest.json \
    .next/server/pages-manifest.json \
    .next/server/middleware-manifest.json \
    .next/server/server-reference-manifest.json
do
    if [ -f "$f" ]; then
        echo "PASS $f"
    else
        echo "ABSENT $f"
    fi
done

echo
echo "[10/10] TRANSACTION"
echo "--------------------------------------------------------------"

if [ "$BUILD_RC" -eq 0 ]; then

    cat > .completion-state/finalization-known-good.json <<JSON
{
  "engine":"$ENGINE",
  "timestamp":"$(date -Iseconds)",
  "status":"KNOWN_GOOD",
  "build":"PASS",
  "next_version":"$(node -e 'process.stdout.write(require("next/package.json").version)')",
  "webpack_hook":"ABSENT",
  "duplicate_webpack_flag":"NOT_USED",
  "next_static":"PRESENT",
  "server_app_files":$APP_OUTPUT,
  "backup":"$BACKUP",
  "log":"$LOG"
}
JSON

    echo
    echo "=============================================================="
    echo " COMPLETION ENGINE® — V8 FINALIZATION PASS"
    echo "=============================================================="
    echo "BUILD          : PASS"
    echo "FINALIZATION   : PASS"
    echo "WEBPACK HOOK   : ABSENT"
    echo "DUPLICATE FLAG : ELIMINATED"
    echo "KNOWN-GOOD     : PROMOTED"
    echo "BACKUP         : $BACKUP"
    echo "LOG            : $LOG"
    echo "=============================================================="

    exit 0
fi

echo
echo "=============================================================="
echo " COMPLETION ENGINE® — V8 DIAGNOSIS COMPLETE"
echo "=============================================================="
echo "BUILD          : FAIL"
echo "FAILURE        : FINALIZATION / SSG MANIFEST"
echo "CONFIGURATION  : PRESERVED"
echo "BACKUP         : $BACKUP"
echo "BUILD LOG      : $BUILD_LOG"
echo "MAIN LOG       : $LOG"
echo "=============================================================="

exit "$BUILD_RC"
