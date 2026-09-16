#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

STAMP="$(date +%Y%m%d_%H%M%S)"

echo "============================================================"
echo " OMEGA® VERIFIED BASELINE LOCK"
echo "============================================================"
echo "ROOT:  $ROOT"
echo "STAMP: $STAMP"
echo

echo "### 1. VERIFY BEFORE COMMIT"

node --check src/core/public-contract.js
echo "PASS: source syntax"

npm test
echo "PASS: 39-test regression suite"

npm run build
echo "PASS: production build"

echo
echo "### 2. GIT INITIALIZATION"

if [ ! -d ".git" ]; then
  git init
fi

git branch -M master

echo "PASS: Git repository"
echo "BRANCH: $(git branch --show-current)"

echo
echo "### 3. IGNORE EPHEMERAL STATE"

touch .gitignore

for entry in \
  ".next/" \
  "node_modules/" \
  ".omega-final-*/" \
  ".omega-release-*/" \
  ".omega-autonomy-*/" \
  ".omega-repair-*/"
do
  grep -qxF "$entry" .gitignore 2>/dev/null || \
    printf '%s\n' "$entry" >> .gitignore
done

echo "PASS: ignore rules"

echo
echo "### 4. STAGE VERIFIED SOURCE"

git add .

echo "PASS: files staged"

echo
echo "### 5. CREATE IMMUTABLE BASELINE"

if git rev-parse --verify HEAD >/dev/null 2>&1; then
  echo "Existing commit detected:"
  git log -1 --oneline

  if ! git diff --cached --quiet; then
    git commit \
      -m "OMEGA: lock verified autonomous engineering baseline"
  else
    echo "PASS: working tree already represented by HEAD"
  fi
else
  git commit \
    -m "OMEGA: establish verified autonomous engineering baseline"
fi

COMMIT="$(git rev-parse HEAD)"

echo
echo "BASELINE COMMIT:"
echo "$COMMIT"

echo
echo "### 6. CREATE BASELINE TAG"

TAG="omega-verified-baseline-$STAMP"

git tag "$TAG" "$COMMIT"

echo "TAG:"
echo "$TAG"

echo
echo "### 7. VERIFY HEAD"

git rev-parse --verify HEAD >/dev/null

echo "PASS: HEAD exists"

echo
echo "### 8. VERIFY BASELINE IDENTITY"

git log -1 --format='commit=%H%nmessage=%s'

echo
echo "### 9. WORKTREE"

git status --short

echo
echo "============================================================"
echo " OMEGA® VERIFIED BASELINE: LOCKED"
echo "============================================================"
echo
echo "COMMIT:"
echo "  $COMMIT"
echo
echo "TAG:"
echo "  $TAG"
echo
echo "ROLLBACK POINT:"
echo "  $COMMIT"
echo
echo "AUTONOMOUS ADVANCEMENT MAY NOW BEGIN."
echo
