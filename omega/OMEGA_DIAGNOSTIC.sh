#!/data/data/com.termux/files/usr/bin/bash
set -e

cd "$HOME/omega"

echo "========================================"
echo "        OMEGA ARCHITECTURE AUDIT"
echo "========================================"
echo

echo "[1] ROOT"
pwd
echo

echo "[2] PACKAGE"
node -e '
const p=require("./package.json");
console.log("name:",p.name);
console.log("version:",p.version);
console.log("private:",p.private);
console.log("type:",p.type || "commonjs");
'
echo

echo "[3] DEPENDENCIES"
node - <<'NODE'
const p=require("./package.json");
console.log(JSON.stringify({
  dependencies:p.dependencies||{},
  devDependencies:p.devDependencies||{}
},null,2));
NODE
echo

echo "[4] TOP-LEVEL STRUCTURE"
find . -maxdepth 2 -type f \
  ! -path './node_modules/*' \
  ! -path './.git/*' \
  | sort
echo

echo "[5] BINARIES"
if [ -d bin ]; then
  find bin -maxdepth 2 -type f -print | sort
else
  echo "NO bin/"
fi
echo

echo "[6] OMEGA ENTRYPOINT"
if [ -f bin/omega.js ]; then
  echo "--- bin/omega.js ---"
  sed -n '1,260p' bin/omega.js
else
  echo "MISSING: bin/omega.js"
fi
echo

echo "[7] TESTS"
if [ -d test ] || [ -d tests ]; then
  find test tests -type f 2>/dev/null | sort
else
  echo "NO test/ OR tests/"
fi
echo

echo "[8] GIT"
if [ -d .git ]; then
  git status --short
  git branch --show-current
  git log -1 --oneline
else
  echo "NOT A GIT REPOSITORY"
fi
echo

echo "========================================"
echo "        END OMEGA AUDIT"
echo "========================================"
