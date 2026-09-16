#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "=== EB PLATFORM® — FULL PROJECT AUDIT ==="
echo

echo "[1] ROOT"
printf 'Files: '; find . -maxdepth 1 -type f | wc -l
printf 'Dirs:  '; find . -maxdepth 1 -type d | wc -l
echo

echo "[2] STEP INVENTORY"
find . -type f -name 'STEP*.sh' | sort -V
echo
echo "Highest numbered STEP:"
find . -type f -name 'STEP*.sh' -printf '%f\n' 2>/dev/null \
  | sed -n 's/^STEP\([0-9][0-9]*\).*/\1/p' \
  | sort -n | tail -1 || true
echo

echo "[3] PROJECT TREE"
find . -maxdepth 3 -not -path './.git/*' -print | sort
echo

echo "[4] FILE COUNTS"
find . -type f -not -path './.git/*' | wc -l
echo

echo "[5] SHELL SCRIPTS"
find . -type f -name '*.sh' | sort
echo

echo "[6] JAVASCRIPT / TYPESCRIPT"
find . -type f \( -name '*.js' -o -name '*.mjs' -o -name '*.cjs' -o -name '*.ts' -o -name '*.tsx' \) \
  -not -path './node_modules/*' | sort
echo

echo "[7] JSON DATA"
find . -type f -name '*.json' -not -path './node_modules/*' | sort
echo

echo "[8] ROUTE / API REFERENCES"
grep -RniE '(/api/|app\.(get|post|put|patch|delete)|router\.(get|post|put|patch|delete))' \
  . --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null | head -300 || true
echo

echo "[9] TODO / PLACEHOLDER / STUBS"
grep -RniE 'TODO|FIXME|PLACEHOLDER|STUB|NOT_IMPLEMENTED|throw new Error' \
  . --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null | head -300 || true
echo

echo "[10] NODE PACKAGE"
if [ -f package.json ]; then
  cat package.json
else
  echo "No package.json"
fi
echo

echo "[11] GIT"
if [ -d .git ]; then
  git status --short
  echo "--- branches ---"
  git branch --all
  echo "--- recent commits ---"
  git log --oneline -20
else
  echo "No Git repository"
fi
echo

echo "[12] RUNNING SERVICES"
ps -ef 2>/dev/null | grep -E 'node|npm|pnpm|yarn' | grep -v grep || true
echo

echo "[13] LISTENING PORTS"
if command -v ss >/dev/null 2>&1; then
  ss -ltnp 2>/dev/null || true
elif command -v netstat >/dev/null 2>&1; then
  netstat -ltnp 2>/dev/null || true
else
  echo "ss/netstat unavailable"
fi
echo

echo "[14] DISK"
du -sh . 2>/dev/null || true

echo
echo "=== FULL AUDIT COMPLETE — READ ONLY ==="
