#!/data/data/com.termux/files/usr/bin/bash

set -Eeuo pipefail

APP="SECURE VAULT®"
START="$(date '+%Y%m%d_%H%M%S')"
TMP="$HOME/.secure-vault-repair-$START"

WARN_BYTES=$((50 * 1024 * 1024))
HARD_BYTES=$((100 * 1024 * 1024))

cleanup() {
    rm -rf "$TMP" 2>/dev/null || true
}

trap cleanup EXIT

mkdir -p "$TMP"

PASS=0
WARN=0
BLOCK=0

pass() {
    echo "[PASS] $1"
    PASS=$((PASS + 1))
}

warn() {
    echo "[WARN] $1"
    WARN=$((WARN + 1))
}

blocked() {
    echo "[BLOCKED] $1"
    BLOCK=$((BLOCK + 1))
}

echo
echo "============================================================"
echo " $APP"
echo " COMPLETE GITHUB REPAIR ENGINE"
echo "============================================================"
echo
echo "Started: $(date)"
echo

# ============================================================
# 1. LOCATE REPOSITORY
# ============================================================

echo "[1/15] Locating Git repository..."

if ! GIT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"; then
    echo "[BLOCKED] Current directory is not a Git repository."
    exit 2
fi

cd "$GIT_ROOT"

pass "Repository located: $GIT_ROOT"

# ============================================================
# 2. IDENTITY
# ============================================================

echo
echo "[2/15] Reading repository identity..."

BRANCH="$(git branch --show-current 2>/dev/null || true)"
REMOTE="$(git remote get-url origin 2>/dev/null || true)"

echo "Repository : $GIT_ROOT"
echo "Branch     : ${BRANCH:-unknown}"
echo "Remote     : ${REMOTE:-none}"

if [ -z "$REMOTE" ]; then
    echo "[BLOCKED] origin remote does not exist."
    exit 2
fi

pass "Origin exists: $REMOTE"

# ============================================================
# 3. REMOTE VALIDATION
# ============================================================

echo
echo "[3/15] Validating GitHub remote..."

if [[ "$REMOTE" == *"EBenterprises/secure-vault"* ]]; then
    pass "Origin points to EBenterprises/secure-vault."
else
    warn "Origin is not the expected EBenterprises/secure-vault repository."
    echo "       $REMOTE"
fi

# ============================================================
# 4. GH AUTH
# ============================================================

echo
echo "[4/15] Checking GitHub CLI authentication..."

if ! command -v gh >/dev/null 2>&1; then
    echo "[BLOCKED] GitHub CLI (gh) is not installed."
    echo "          Install with: pkg install gh"
    exit 2
fi

if gh auth status >/dev/null 2>&1; then
    pass "GitHub CLI authentication is available."
else
    echo "[BLOCKED] GitHub CLI is not authenticated."
    echo "          Run: gh auth login"
    exit 2
fi

# ============================================================
# 5. WORKTREE
# ============================================================

echo
echo "[5/15] Checking working tree..."

git status --short > "$TMP/status"

if [ -s "$TMP/status" ]; then
    warn "Working tree contains changes."
    cat "$TMP/status"
else
    pass "Working tree is clean."
fi

# ============================================================
# 6. UPDATE GITIGNORE
# ============================================================

echo
echo "[6/15] Hardening .gitignore..."

touch .gitignore

add_ignore() {
    local rule="$1"

    if ! grep -Fqx "$rule" .gitignore 2>/dev/null; then
        printf '%s\n' "$rule" >> .gitignore
    fi
}

add_ignore ""
add_ignore "# Secure Vault® Android / Gradle generated artifacts"
add_ignore ".gradle/"
add_ignore "**/.gradle/"
add_ignore "build/"
add_ignore "**/build/"
add_ignore "bin/"
add_ignore ".buildozer/"
add_ignore "**/.buildozer/"
add_ignore "*.zip"
add_ignore "*.tar.gz"
add_ignore "*.tar"
add_ignore "*.apk"
add_ignore "*.aab"

git add .gitignore

if git diff --cached --quiet; then
    pass ".gitignore already contains required protections."
else
    git commit -m "Chore: harden generated artifact exclusions" >/dev/null
    pass ".gitignore hardened."
fi

# ============================================================
# 7. DETECT TRACKED LARGE FILES
# ============================================================

echo
echo "[7/15] Checking currently tracked files..."

: > "$TMP/tracked_large"

while IFS= read -r -d '' file; do

    [ -f "$file" ] || continue

    size="$(stat -c '%s' "$file" 2>/dev/null || echo 0)"

    if [ "$size" -ge "$HARD_BYTES" ]; then
        mb=$((size / 1024 / 1024))
        echo "$size|$file" >> "$TMP/tracked_large"
        blocked "Tracked file is ${mb} MB: $file"

    elif [ "$size" -ge "$WARN_BYTES" ]; then
        mb=$((size / 1024 / 1024))
        echo "$size|$file" >> "$TMP/tracked_large"
        warn "Tracked file is ${mb} MB: $file"
    fi

done < <(git ls-files -z)

if [ ! -s "$TMP/tracked_large" ]; then
    pass "No currently tracked files exceed 50 MB."
fi

# ============================================================
# 8. DETECT GENERATED ARTIFACTS
# ============================================================

echo
echo "[8/15] Checking tracked Android/Gradle artifacts..."

git ls-files > "$TMP/files"

GENERATED="$(grep -Ei \
    '(^|/)(\.gradle/|build/|\.buildozer/|bin/|gradle-[0-9].*(/|\.zip)|.*\.gradle\.zip$)' \
    "$TMP/files" || true)"

if [ -n "$GENERATED" ]; then
    echo "[WARNING] Generated artifacts currently tracked:"
    echo "$GENERATED"
    WARN=$((WARN + 1))
else
    pass "No obvious generated Android/Gradle directories are tracked."
fi

# ============================================================
# 9. REMOVE GENERATED ARTIFACTS FROM CURRENT INDEX
# ============================================================

echo
echo "[9/15] Removing generated artifacts from Git index..."

REMOVED=0

while IFS= read -r file; do

    [ -n "$file" ] || continue

    if git check-ignore -q "$file" 2>/dev/null; then
        git rm --cached --ignore-unmatch "$file" >/dev/null 2>&1 || true
        REMOVED=$((REMOVED + 1))
    fi

done < "$TMP/files"

if [ "$REMOVED" -gt 0 ]; then
    git commit -m "Chore: remove generated artifacts from repository" >/dev/null
    pass "Removed $REMOVED ignored generated artifact(s) from the index."
else
    pass "No ignored generated artifacts required removal."
fi

# ============================================================
# 10. FIND HISTORY OBJECTS
# ============================================================

echo
echo "[10/15] Scanning Git history for forbidden artifacts..."

git rev-list --objects --all > "$TMP/history"

HISTORY_MATCHES="$(grep -Ei \
    '(^|/)(gradle-[0-9].*(\.zip|/)|\.gradle/|build/|\.buildozer/|bin/)' \
    "$TMP/history" || true)"

if [ -n "$HISTORY_MATCHES" ]; then
    echo
    echo "[WARNING] Generated artifacts exist in Git history:"
    echo "$HISTORY_MATCHES" | head -100
else
    pass "No obvious generated artifact paths found in Git history."
fi

# ============================================================
# 11. CHECK GIT OBJECT SIZES
# ============================================================

echo
echo "[11/15] Checking Git object database..."

: > "$TMP/objects"

if compgen -G ".git/objects/pack/*.idx" >/dev/null 2>&1; then

    git verify-pack -v .git/objects/pack/*.idx 2>/dev/null |
        awk '$1 ~ /^[0-9a-f]{40}$/ && $3 ~ /^[0-9]+$/ {
            print $1 "|" $3
        }' |
        sort -t'|' -k2 -n |
        tail -100 > "$TMP/objects"

else
    echo "[INFO] No pack index currently present."
fi

LARGE_OBJECTS=0

while IFS='|' read -r hash size; do

    [ -n "${hash:-}" ] || continue

    if [ "$size" -ge "$HARD_BYTES" ]; then

        mb=$((size / 1024 / 1024))

        path="$(git rev-list --objects --all 2>/dev/null |
            awk -v h="$hash" '$1 == h {$1=""; sub(/^ /,""); print; exit}')"

        blocked "Git object ${mb} MB${path:+: $path}"
        LARGE_OBJECTS=$((LARGE_OBJECTS + 1))

    elif [ "$size" -ge "$WARN_BYTES" ]; then

        mb=$((size / 1024 / 1024))

        path="$(git rev-list --objects --all 2>/dev/null |
            awk -v h="$hash" '$1 == h {$1=""; sub(/^ /,""); print; exit}')"

        warn "Git object ${mb} MB${path:+: $path}"
        LARGE_OBJECTS=$((LARGE_OBJECTS + 1))

    fi

done < "$TMP/objects"

if [ "$LARGE_OBJECTS" -eq 0 ]; then
    pass "No packed Git objects exceed 50 MB."
fi

# ============================================================
# 12. HISTORY REWRITE
# ============================================================

echo
echo "[12/15] Evaluating Git history cleanup..."

if [ -n "$HISTORY_MATCHES" ] || [ "$LARGE_OBJECTS" -gt 0 ]; then

    if ! command -v git-filter-repo >/dev/null 2>&1; then

        echo "[INFO] git-filter-repo is not installed."

        if command -v pip >/dev/null 2>&1; then
            echo "[*] Installing git-filter-repo..."
            pip install --user git-filter-repo >/dev/null
        elif command -v pip3 >/dev/null 2>&1; then
            echo "[*] Installing git-filter-repo..."
            pip3 install --user git-filter-repo >/dev/null
        else
            echo "[BLOCKED] Python pip is unavailable."
            echo "          Install git-filter-repo manually."
            exit 2
        fi
    fi

    FILTER_REPO="$(command -v git-filter-repo 2>/dev/null || true)"

    if [ -z "$FILTER_REPO" ]; then
        FILTER_REPO="$HOME/.local/bin/git-filter-repo"
    fi

    if [ ! -x "$FILTER_REPO" ]; then
        echo "[BLOCKED] git-filter-repo could not be located."
        exit 2
    fi

    echo "[*] Removing generated Gradle/build artifacts from ALL Git history..."

    "$FILTER_REPO" --force \
        --path-glob 'native-android-app/gradle-*.zip' \
        --path-glob 'native-android-app/gradle-*.zip.*' \
        --path-glob 'native-android-app/gradle-*/' \
        --path-glob '**/.gradle/**' \
        --path-glob '**/build/**' \
        --path-glob '**/.buildozer/**' \
        --path-glob '**/bin/**' \
        --invert-paths

    pass "Generated artifacts removed from reachable Git history."

else

    pass "History rewrite is not required."
fi

# ============================================================
# 13. REPACK / GC
# ============================================================

echo
echo "[13/15] Repacking Git object database..."

git reflog expire --expire=now --all
git gc --prune=now --aggressive

pass "Git object database compacted."

# ============================================================
# 14. FINAL SAFETY AUDIT
# ============================================================

echo
echo "[14/15] Running final GitHub safety audit..."

FINAL_BLOCK=0

git rev-list --objects --all > "$TMP/final_history"

FINAL_PATHS="$(grep -Ei \
    '(^|/)(gradle-[0-9].*(\.zip|/)|\.gradle/|build/|\.buildozer/|bin/)' \
    "$TMP/final_history" || true)"

if [ -n "$FINAL_PATHS" ]; then
    echo "[BLOCKED] Forbidden generated paths remain in history:"
    echo "$FINAL_PATHS" | head -100
    FINAL_BLOCK=1
fi

: > "$TMP/final_objects"

if compgen -G ".git/objects/pack/*.idx" >/dev/null 2>&1; then

    git verify-pack -v .git/objects/pack/*.idx 2>/dev/null |
        awk '$1 ~ /^[0-9a-f]{40}$/ && $3 ~ /^[0-9]+$/ {
            print $1 "|" $3
        }' |
        sort -t'|' -k2 -n |
        tail -100 > "$TMP/final_objects"
fi

while IFS='|' read -r hash size; do

    [ -n "${hash:-}" ] || continue

    if [ "$size" -ge "$HARD_BYTES" ]; then

        mb=$((size / 1024 / 1024))

        path="$(git rev-list --objects --all 2>/dev/null |
            awk -v h="$hash" '$1 == h {$1=""; sub(/^ /,""); print; exit}')"

        echo "[BLOCKED] Final Git object ${mb} MB${path:+: $path}"
        FINAL_BLOCK=1

    fi

done < "$TMP/final_objects"

if [ "$FINAL_BLOCK" -eq 1 ]; then
    echo
    echo "============================================================"
    echo " FINAL STATUS: BLOCKED"
    echo "============================================================"
    echo
    echo "The repository still contains GitHub-blocking objects."
    echo "NO PUSH WAS PERFORMED."
    echo
    exit 2
fi

pass "Final audit contains no GitHub-blocking objects."

# ============================================================
# 15. PUSH
# ============================================================

echo
echo "[15/15] Preparing authenticated GitHub push..."

gh auth setup-git

if [ "$BRANCH" != "main" ]; then
    echo "[*] Current branch is '$BRANCH'."
    echo "[*] Push will target current branch."
fi

echo
echo "============================================================"
echo " READY TO PUSH"
echo "============================================================"
echo
echo "Repository : $GIT_ROOT"
echo "Remote     : $(git remote get-url origin)"
echo "Branch     : $BRANCH"
echo
echo "The repository has passed the large-file safety audit."
echo

if git ls-remote origin HEAD >/dev/null 2>&1; then
    echo "[*] GitHub remote is reachable."
else
    echo "[BLOCKED] GitHub remote cannot be reached."
    exit 2
fi

echo "[*] Pushing rewritten history with force-with-lease..."

git push -u origin "$BRANCH" --force-with-lease

echo
echo "============================================================"
echo " REPAIR COMPLETE"
echo "============================================================"
echo
echo "[PASS] Git history cleaned."
echo "[PASS] Generated artifacts excluded."
echo "[PASS] Large-object audit passed."
echo "[PASS] GitHub authentication passed."
echo "[PASS] Repository pushed successfully."
echo
echo "Finished: $(date)"
echo
