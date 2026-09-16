#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

cd "$HOME/omega"

echo
echo "================================================"
echo " OMEGA® NEXT8 — JSX-AWARE SOURCE AUDIT REPAIR"
echo "================================================"
echo

# ------------------------------------------------
# BACKUP CURRENT NEXT8
# ------------------------------------------------

BACKUP="backups/next8-jsx-aware-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP"

cp OMEGA_NEXT8.sh "$BACKUP/OMEGA_NEXT8.sh"
echo "[OMEGA] NEXT8 backup ........ PASS"
echo "[OMEGA] Backup: $BACKUP/OMEGA_NEXT8.sh"

# ------------------------------------------------
# REPAIR THE SOURCE AUDIT
#
# Node --check is valid for .js files that contain
# ordinary JavaScript, but it cannot parse JSX.
#
# Next.js App Router files under src/app may contain
# JSX and must therefore be validated through the
# Next.js build/compiler rather than node --check.
# ------------------------------------------------

echo
echo "[OMEGA] Rebuilding source-audit logic..."

node --input-type=module <<'JS'
import fs from "node:fs"

const file = "OMEGA_NEXT8.sh"

let source = fs.readFileSync(file, "utf8")

const oldBlock = `SOURCE_FAILURE=0

while IFS= read -r -d '' file; do
  if ! node --check "$file" >/dev/null 2>&1; then
    echo "[OMEGA] SYNTAX FAILURE: $file"
    SOURCE_FAILURE=1
  fi
done < <(
  find src bin tests \\
    -type f \\
    -name "*.js" \\
    -print0 2>/dev/null
)

if [ "$SOURCE_FAILURE" -ne 0 ]; then
  echo "[OMEGA] Source syntax ........ FAIL"
  exit 1
fi

echo "[OMEGA] Source syntax ........ PASS"`

const newBlock = `SOURCE_FAILURE=0

echo "[OMEGA] Detecting JavaScript/JSX source..."

while IFS= read -r -d '' file; do

  case "$file" in

    src/app/*.js|src/app/**/*.js)
      echo "[OMEGA] JSX source ............ $file"
      ;;

    *)
      if ! node --check "$file" >/dev/null 2>&1; then
        echo "[OMEGA] SYNTAX FAILURE: $file"
        SOURCE_FAILURE=1
      fi
      ;;

  esac

done < <(
  find src bin tests \\
    -type f \\
    -name "*.js" \\
    -print0 2>/dev/null
)

if [ "$SOURCE_FAILURE" -ne 0 ]; then
  echo "[OMEGA] JavaScript syntax ...... FAIL"
  exit 1
fi

echo "[OMEGA] JavaScript syntax ...... PASS"
echo "[OMEGA] JSX deferred to Next.js compiler"`

if (!source.includes(oldBlock)) {
  console.error("[OMEGA] Expected NEXT8 audit block was not found.")
  process.exit(1)
}

source = source.replace(oldBlock, newBlock)

fs.writeFileSync(file, source)

console.log("[OMEGA] NEXT8 audit logic .... PASS")
JS

# ------------------------------------------------
# ADD A REAL NEXT.JS JSX VALIDATION STEP
# ------------------------------------------------

echo
echo "[OMEGA] Installing JSX-aware validation step..."

node --input-type=module <<'JS'
import fs from "node:fs"

const file = "OMEGA_NEXT8.sh"
let source = fs.readFileSync(file, "utf8")

const marker = `echo "[OMEGA] JavaScript syntax ...... PASS"
echo "[OMEGA] JSX deferred to Next.js compiler"`

const replacement = `echo "[OMEGA] JavaScript syntax ...... PASS"
echo "[OMEGA] JSX deferred to Next.js compiler"

# Next.js is the authoritative parser/compiler for App Router JSX.
if [ -f package.json ]; then
  echo
  echo "[OMEGA] Validating Next.js application..."

  if ! npm run build -- --webpack >/dev/null 2>&1; then
    echo "[OMEGA] Next.js compilation ..... FAIL"
    echo
    echo "[OMEGA] Run this directly for the exact compiler error:"
    echo "npm run build -- --webpack"
    exit 1
  fi

  echo "[OMEGA] Next.js compilation ..... PASS"
fi`

if (!source.includes(marker)) {
  console.error("[OMEGA] JSX validation marker not found.")
  process.exit(1)
}

source = source.replace(marker, replacement)

fs.writeFileSync(file, source)

console.log("[OMEGA] JSX compiler gate ..... PASS")
JS

# ------------------------------------------------
# MAKE EXECUTABLE
# ------------------------------------------------

chmod +x OMEGA_NEXT8.sh

# ------------------------------------------------
# VALIDATE THE REPAIRED SCRIPT ITSELF
# ------------------------------------------------

echo
echo "[OMEGA] Validating NEXT8 script..."

bash -n OMEGA_NEXT8.sh

echo "[OMEGA] NEXT8 shell syntax ...... PASS"

# ------------------------------------------------
# TEST JSX CLASSIFICATION
# ------------------------------------------------

echo
echo "[OMEGA] Testing JSX classification..."

for file in src/app/page.js src/app/layout.js; do
  if [ -f "$file" ]; then
    echo "[OMEGA] JSX recognized ........ $file"
  else
    echo "[OMEGA] Missing app file ....... $file"
    exit 1
  fi
done

# ------------------------------------------------
# RUN NEXT8
# ------------------------------------------------

echo
echo "================================================"
echo " OMEGA® NEXT8 — RE-RUN"
echo "================================================"
echo

bash OMEGA_NEXT8.sh
