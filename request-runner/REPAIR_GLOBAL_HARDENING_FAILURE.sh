#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

echo "=============================================================="
echo " REQUEST RUNNER® — GLOBAL HARDENING REPAIR"
echo "=============================================================="

PASS=0
FAIL=0
CHANGES=0

ok() {
    echo "✓ $1"
    PASS=$((PASS+1))
}

fail() {
    echo "✗ $1"
    FAIL=$((FAIL+1))
}

changed() {
    echo "✓ $1"
    PASS=$((PASS+1))
    CHANGES=$((CHANGES+1))
}

echo
echo "[1] INSPECT"
echo "--------------------------------------------------------------"

for f in \
    GLOBAL_LOCALIZATION_HARDENING.sh \
    EB_PLATFORM.sh \
    REQUEST_RUNNER_RELEASE_GATE.sh
do
    if [ -f "$f" ]; then
        ok "$f exists"
    else
        fail "$f missing"
    fi
done

[ -d i18n ] && ok "i18n directory exists" || fail "i18n directory missing"

if [ "$FAIL" -ne 0 ]; then
    echo
    echo "INSPECTION FAILED — NO MUTATION."
    exit 1
fi

echo
echo "[2] BACKUP"
echo "--------------------------------------------------------------"

STAMP="$(date '+%Y%m%d-%H%M%S')"
BACKUP="$ROOT/.global-hardening-repair-$STAMP"

mkdir -p "$BACKUP"
cp -p GLOBAL_LOCALIZATION_HARDENING.sh "$BACKUP/"
ok "Backup created: $BACKUP"

echo
echo "[3] LOCATE UNSAFE REPORT VARIABLE"
echo "--------------------------------------------------------------"

if grep -nF '$i18n' GLOBAL_LOCALIZATION_HARDENING.sh >/dev/null 2>&1; then
    grep -nF '$i18n' GLOBAL_LOCALIZATION_HARDENING.sh | head -n 10
    changed "Unsafe \$i18n reference located"
else
    ok "No literal \$i18n reference found"
fi

echo
echo "[4] PATCH"
echo "--------------------------------------------------------------"

# Replace any standalone report reference to $i18n with the real path.
# No Python dependency required.
if grep -qF '$i18n' GLOBAL_LOCALIZATION_HARDENING.sh; then
    sed -i 's/^\$i18n$/echo "$ROOT\/i18n"/' GLOBAL_LOCALIZATION_HARDENING.sh
    sed -i 's/echo "\$i18n"/echo "$ROOT\/i18n"/g' GLOBAL_LOCALIZATION_HARDENING.sh
    changed "Repaired localization-root report reference"
else
    ok "No localization-root patch required"
fi

echo
echo "[5] SYNTAX"
echo "--------------------------------------------------------------"

if bash -n GLOBAL_LOCALIZATION_HARDENING.sh; then
    ok "Global hardening syntax"
else
    fail "Global hardening syntax"

    cp -p "$BACKUP/GLOBAL_LOCALIZATION_HARDENING.sh" \
        GLOBAL_LOCALIZATION_HARDENING.sh

    echo "Original restored."
    exit 1
fi

echo
echo "[6] I18N VALIDATION"
echo "--------------------------------------------------------------"

for f in \
    i18n/config.json \
    i18n/locales/registry.json \
    i18n/catalog/LANGUAGE_CATALOG.json \
    i18n/catalog/IP_METADATA.json \
    i18n/locale-resolver.js \
    i18n/rtl/global.css \
    i18n/legal/legal-document.schema.json \
    i18n/scripts/translation-audit.js
do
    if [ -s "$f" ]; then
        ok "$f"
    else
        fail "$f"
    fi
done

if node --check i18n/locale-resolver.js >/dev/null 2>&1 &&
   node --check i18n/scripts/translation-audit.js >/dev/null 2>&1
then
    ok "I18N JavaScript syntax"
else
    fail "I18N JavaScript syntax"
fi

if node i18n/scripts/translation-audit.js >/dev/null 2>&1; then
    ok "Global I18N audit"
else
    fail "Global I18N audit"
fi

echo
echo "[7] PLATFORM SYNTAX"
echo "--------------------------------------------------------------"

for f in \
    EB_PLATFORM.sh \
    start.sh \
    launch.sh \
    REQUEST_RUNNER_RELEASE_GATE.sh
do
    if [ -f "$f" ] && bash -n "$f"; then
        ok "$f syntax"
    elif [ -f "$f" ]; then
        fail "$f syntax"
    fi
done

if [ -f server.js ] && node --check server.js >/dev/null 2>&1; then
    ok "server.js syntax"
else
    fail "server.js syntax"
fi

echo
echo "[8] RESULT"
echo "--------------------------------------------------------------"

echo "Changes: $CHANGES"
echo "PASS:    $PASS"
echo "FAIL:    $FAIL"
echo "Backup:  $BACKUP"

if [ "$FAIL" -eq 0 ]; then
    echo
    echo "STATUS: GREEN"
    echo "GLOBAL HARDENING SCRIPT REPAIRED"
else
    echo
    echo "STATUS: RED"
    echo "REPAIR INCOMPLETE"
    exit 1
fi

echo "=============================================================="
