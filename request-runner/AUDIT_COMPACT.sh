#!/data/data/com.termux/files/usr/bin/bash
set -e

OUT="AUDIT_COMPACT.txt"
{
echo "=== REQUEST-RUNNER® AUDIT ==="
echo "DATE: $(date)"
echo

echo "[STEPS]"
find . -type f -name 'STEP*.sh' -printf '%f\n' 2>/dev/null |
sed -n 's/^STEP\([0-9][0-9]*\).*/\1/p' |
sort -n |
awk '
NR==1{first=$1}
{last=$1; count++}
END{printf "count=%s first=%s last=%s\n",count,first,last}
'

echo
echo "[DIRECTORIES]"
find . -maxdepth 2 -type d \
-not -path './.git*' \
-not -path './node_modules*' |
sort

echo
echo "[FILE COUNTS]"
printf "total="; find . -type f -not -path './.git/*' -not -path './node_modules/*' | wc -l
printf "shell="; find . -type f -name '*.sh' | wc -l
printf "js_ts="; find . -type f \( -name '*.js' -o -name '*.mjs' -o -name '*.cjs' -o -name '*.ts' -o -name '*.tsx' \) -not -path './node_modules/*' | wc -l
printf "json="; find . -type f -name '*.json' -not -path './node_modules/*' | wc -l

echo
echo "[STEP FILES]"
find . -type f -name 'STEP*.sh' -printf '%f\n' 2>/dev/null | sort -V

echo
echo "[GIT]"
if [ -d .git ]; then
  git status --short
  echo "commits=$(git rev-list --count HEAD 2>/dev/null || echo 0)"
  git log -1 --oneline 2>/dev/null || true
else
  echo "NO_GIT"
fi

echo
echo "[SERVICES]"
ps -ef 2>/dev/null | grep -E 'node|npm|pnpm|yarn' | grep -v grep || true

echo
echo "[PORTS]"
ss -ltn 2>/dev/null | grep -E ':(3000|3001|8080|8081)' || true

echo
echo "[SUSPICIOUS]"
grep -RIlE 'TODO|FIXME|PLACEHOLDER|NOT_IMPLEMENTED' . \
--exclude-dir=node_modules --exclude-dir=.git 2>/dev/null |
wc -l

echo
echo "[SIZE]"
du -sh . 2>/dev/null

echo
echo "=== END ==="
} > "$OUT"

cat "$OUT"
