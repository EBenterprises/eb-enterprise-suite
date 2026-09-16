#!/data/data/com.termux/files/usr/bin/bash

set -u

# ============================================================
# GitHub Repository Pre-Push Audit
# EB Enterprises®
# ============================================================

REPO="${1:-$(pwd)}"

WARN_MB=50
HARD_MB=100

WARN_BYTES=$((WARN_MB * 1024 * 1024))
HARD_BYTES=$((HARD_MB * 1024 * 1024))

PASS=0
WARN=0
BLOCK=0

cd "$REPO" 2>/dev/null || {
    echo "[BLOCKED] Repository does not exist: $REPO"
    exit 1
}

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "[BLOCKED] Not a Git repository:"
    echo "         $REPO"
    exit 1
fi

echo
echo "============================================================"
echo " GitHub Repository Pre-Push Audit"
echo "============================================================"
echo "Repository : $(pwd)"
echo "Branch     : $(git branch --show-current 2>/dev/null || echo unknown)"
echo "Remote     : $(git remote get-url origin 2>/dev/null || echo none)"
echo "============================================================"
echo

# ------------------------------------------------------------
# 1. Git status
# ------------------------------------------------------------

echo "[1/9] Checking working tree..."

if git diff --quiet && git diff --cached --quiet; then
    echo "[PASS] No unstaged/staged modifications."
    PASS=$((PASS + 1))
else
    echo "[WARN] Working tree contains changes."
    git status --short
    WARN=$((WARN + 1))
fi

echo

# ------------------------------------------------------------
# 2. Check tracked files by actual filesystem size
# ------------------------------------------------------------

echo "[2/9] Checking tracked files for large files..."

TMP_TRACKED="/tmp/eb_tracked_files_$$"
TMP_LARGE="/tmp/eb_large_files_$$"

git ls-files > "$TMP_TRACKED"

: > "$TMP_LARGE"

while IFS= read -r file; do

    [ -f "$file" ] || continue

    SIZE=$(stat -c%s "$file" 2>/dev/null || echo 0)

    if [ "$SIZE" -ge "$HARD_BYTES" ]; then
        echo "$SIZE|BLOCKED|$file" >> "$TMP_LARGE"
    elif [ "$SIZE" -ge "$WARN_BYTES" ]; then
        echo "$SIZE|WARNING|$file" >> "$TMP_LARGE"
    fi

done < "$TMP_TRACKED"

if [ ! -s "$TMP_LARGE" ]; then
    echo "[PASS] No tracked files >= ${WARN_MB} MB."
    PASS=$((PASS + 1))
else
    while IFS='|' read -r SIZE LEVEL FILE; do
        MB=$((SIZE / 1024 / 1024))
        echo "[$LEVEL] ${MB} MB - $FILE"

        if [ "$LEVEL" = "BLOCKED" ]; then
            BLOCK=$((BLOCK + 1))
        else
            WARN=$((WARN + 1))
        fi
    done < "$TMP_LARGE"
fi

echo

# ------------------------------------------------------------
# 3. Gradle / Android generated artifacts
# ------------------------------------------------------------

echo "[3/9] Checking Android / Gradle generated artifacts..."

GRADLE_FOUND=0

for pattern in \
    ".gradle" \
    "build" \
    "gradle-[0-9]*" \
    "*.gradle.zip" \
    "gradle-*-bin.zip" \
    "gradle-*-all.zip"
do

    MATCHES=$(git ls-files | grep -E "(^|/)$pattern(/|$)" 2>/dev/null || true)

    if [ -n "$MATCHES" ]; then
        echo "[WARNING] Potential generated artifact:"
        echo "$MATCHES"
        GRADLE_FOUND=1
    fi
done

if [ "$GRADLE_FOUND" -eq 0 ]; then
    echo "[PASS] No obvious Gradle/build artifacts tracked."
    PASS=$((PASS + 1))
else
    WARN=$((WARN + 1))
fi

echo

# ------------------------------------------------------------
# 4. Check .gitignore
# ------------------------------------------------------------

echo "[4/9] Checking .gitignore..."

if [ ! -f .gitignore ]; then
    echo "[WARNING] No .gitignore exists."
    WARN=$((WARN + 1))
else

    REQUIRED_PATTERNS=(
        ".gradle/"
        "build/"
    )

    IGNORE_OK=1

    for pattern in "${REQUIRED_PATTERNS[@]}"; do
        if ! grep -Fqx "$pattern" .gitignore 2>/dev/null; then
            echo "[WARNING] Missing .gitignore rule: $pattern"
            IGNORE_OK=0
        fi
    done

    if [ "$IGNORE_OK" -eq 1 ]; then
        echo "[PASS] Basic Android/Gradle ignore rules present."
        PASS=$((PASS + 1))
    else
        WARN=$((WARN + 1))
    fi
fi

echo

# ------------------------------------------------------------
# 5. Check ignored files that are accidentally tracked
# ------------------------------------------------------------

echo "[5/9] Checking ignored-but-tracked files..."

IGNORED_TRACKED=0

while IFS= read -r file; do

    if git check-ignore -q "$file" 2>/dev/null; then
        echo "[WARNING] Tracked file is ignored:"
        echo "          $file"
        IGNORED_TRACKED=1
    fi

done < "$TMP_TRACKED"

if [ "$IGNORED_TRACKED" -eq 0 ]; then
    echo "[PASS] No ignored files are currently tracked."
    PASS=$((PASS + 1))
else
    WARN=$((WARN + 1))
fi

echo

# ------------------------------------------------------------
# 6. Search Git history for large objects
# ------------------------------------------------------------

echo "[6/9] Scanning Git history for large objects..."

PACK_FOUND=0

if ls .git/objects/pack/*.idx >/dev/null 2>&1; then

    git verify-pack -v .git/objects/pack/*.idx 2>/dev/null \
        | awk '$1 ~ /^[0-9a-f]+$/ && $3 ~ /^[0-9]+$/ {print $1 "|" $3}' \
        | sort -t'|' -k2 -n \
        | tail -50 \
        > "/tmp/eb_git_objects_$$"

    while IFS='|' read -r HASH SIZE; do

        [ -n "$HASH" ] || continue

        if [ "$SIZE" -ge "$HARD_BYTES" ]; then
            MB=$((SIZE / 1024 / 1024))

            PATHS=$(git rev-list --objects --all 2>/dev/null \
                | grep "^$HASH " \
                | cut -d' ' -f2- || true)

            echo "[BLOCKED] Git object ${MB} MB"
            [ -n "$PATHS" ] && echo "          $PATHS"

            BLOCK=$((BLOCK + 1))
            PACK_FOUND=1

        elif [ "$SIZE" -ge "$WARN_BYTES" ]; then
            MB=$((SIZE / 1024 / 1024))

            PATHS=$(git rev-list --objects --all 2>/dev/null \
                | grep "^$HASH " \
                | cut -d' ' -f2- || true)

            echo "[WARNING] Git object ${MB} MB"
            [ -n "$PATHS" ] && echo "          $PATHS"

            WARN=$((WARN + 1))
            PACK_FOUND=1
        fi

    done < "/tmp/eb_git_objects_$$"

else
    echo "[INFO] No packed Git objects found."
fi

if [ "$PACK_FOUND" -eq 0 ]; then
    echo "[PASS] No large packed Git objects detected."
    PASS=$((PASS + 1))
fi

echo

# ------------------------------------------------------------
# 7. Search history for known dangerous artifact names
# ------------------------------------------------------------

echo "[7/9] Searching Git history for generated artifacts..."

HISTORY_MATCHES=$(git rev-list --objects --all 2>/dev/null \
    | grep -Ei \
    '(^|/)(gradle-[0-9].*(\.zip|/)|\.gradle/|build/)' \
    || true)

if [ -z "$HISTORY_MATCHES" ]; then
    echo "[PASS] No obvious Gradle/build artifacts found in history."
    PASS=$((PASS + 1))
else
    echo "[WARNING] Generated artifacts exist in Git history:"
    echo "$HISTORY_MATCHES" | head -50
    WARN=$((WARN + 1))
fi

echo

# ------------------------------------------------------------
# 8. Check remote connectivity
# ------------------------------------------------------------

echo "[8/9] Checking GitHub remote..."

if git remote get-url origin >/dev/null 2>&1; then

    REMOTE_URL=$(git remote get-url origin)

    if git ls-remote origin HEAD >/dev/null 2>&1; then
        echo "[PASS] GitHub remote reachable."
        echo "       $REMOTE_URL"
        PASS=$((PASS + 1))
    else
        echo "[WARNING] GitHub remote exists but could not be contacted."
        WARN=$((WARN + 1))
    fi

else
    echo "[WARNING] No 'origin' remote configured."
    WARN=$((WARN + 1))
fi

echo

# ------------------------------------------------------------
# 9. Summary
# ------------------------------------------------------------

rm -f "$TMP_TRACKED"
rm -f "$TMP_LARGE"
rm -f "/tmp/eb_git_objects_$$"

echo "============================================================"
echo " AUDIT RESULT"
echo "============================================================"
echo
echo "PASS     : $PASS"
echo "WARNING  : $WARN"
echo "BLOCKED  : $BLOCK"
echo

if [ "$BLOCK" -gt 0 ]; then

    echo "STATUS   : BLOCKED"
    echo
    echo "GitHub push should NOT be attempted."
    echo
    echo "Reason:"
    echo "One or more files/objects are at or above GitHub's"
    echo "100 MB hard file-size limit."
    echo
    echo "Large objects may need to be removed from Git history,"
    echo "not merely deleted from the working directory."
    echo
    exit 2

elif [ "$WARN" -gt 0 ]; then

    echo "STATUS   : WARNING"
    echo
    echo "Review the warnings before pushing."
    echo
    exit 1

else

    echo "STATUS   : SAFE"
    echo
    echo "No obvious GitHub large-file problems detected."
    echo
    exit 0

fi
