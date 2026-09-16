#!/data/data/com.termux/files/usr/bin/bash
set -u

cd "$HOME/request-runner" || exit 1

STAMP="$(date +%Y%m%d-%H%M%S)"
LOG=".completion-logs/artifact-layout-$STAMP.log"

mkdir -p .completion-logs

exec > >(tee "$LOG") 2>&1

clear

echo "=============================================================="
echo " COMPLETION ENGINE® — NEXT 16 ARTIFACT LAYOUT AUDIT"
echo "=============================================================="
echo

echo "[1/6] Build metadata"
echo "--------------------------------------------------------------"

echo "Next: $(node -p "require('next/package.json').version")"
echo "Build script: $(node -p "require('./package.json').scripts.build")"
echo

echo "[2/6] Manifest inventory"
echo "--------------------------------------------------------------"

for f in \
  .next/server/pages-manifest.json \
  .next/server/app-paths-manifest.json \
  .next/server/middleware-manifest.json \
  .next/server/server-reference-manifest.json \
  .next/server/next-font-manifest.json
do
  if [ -f "$f" ]; then
    echo "✓ $f"
  else
    echo "- $f"
  fi
done

echo

echo "[3/6] Actual server artifact tree"
echo "--------------------------------------------------------------"

if [ -d .next/server ]; then
  find .next/server -type f \
    ! -name '*.map' \
    | sort \
    | head -250
else
  echo "✗ .next/server missing"
  exit 1
fi

echo

echo "[4/6] Searching for emitted API route modules"
echo "--------------------------------------------------------------"

COUNT="$(find .next/server -type f \
  \( -name 'route.js' -o -name 'route.js.nft.json' \) \
  | wc -l)"

echo "route.js artifact count: $COUNT"

find .next/server -type f \
  \( -name 'route.js' -o -name 'route.js.nft.json' \) \
  | sort

echo

echo "[5/6] Inspecting App Router manifest"
echo "--------------------------------------------------------------"

node <<'NODE'
const fs = require("fs");

const f = ".next/server/app-paths-manifest.json";

if (!fs.existsSync(f)) {
  console.error("✗ app-paths-manifest.json missing");
  process.exit(1);
}

const manifest = JSON.parse(fs.readFileSync(f, "utf8"));

const entries = Object.keys(manifest);

console.log("App manifest entries:", entries.length);

for (const entry of entries) {
  if (entry.includes("/api/")) {
    console.log("API:", entry);
  }
}

console.log("✓ App Router manifest readable");
NODE

echo

echo "[6/6] Checking middleware applicability"
echo "--------------------------------------------------------------"

MIDDLEWARE_FILES="$(
  find . \
    -path './node_modules' -prune -o \
    -path './.next' -prune -o \
    -type f \
    \( -name 'middleware.js' \
       -o -name 'middleware.ts' \
       -o -name 'middleware.mjs' \
       -o -name 'middleware.cjs' \) \
    -print 2>/dev/null
)"

if [ -n "$MIDDLEWARE_FILES" ]; then
  echo "Middleware source detected:"
  echo "$MIDDLEWARE_FILES"
else
  echo "✓ No middleware source detected"
  echo "✓ middleware-manifest.json is therefore not required"
fi

echo
echo "=============================================================="
echo " ARTIFACT AUDIT COMPLETE"
echo "=============================================================="
echo "Build itself is NOT being rerun."
echo "No source files modified."
echo "Log: $LOG"
echo "=============================================================="
