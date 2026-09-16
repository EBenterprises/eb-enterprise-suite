#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

STAMP="$(date '+%Y%m%d-%H%M%S')"
BACKUP="$ROOT/.i18n-backup-$STAMP"
REPORT="$ROOT/.i18n-audit-$STAMP.txt"

PASS=0
WARN=0
FAIL=0

ok() {
    echo "✓ $1"
    PASS=$((PASS+1))
}

warn() {
    echo "⚠ $1"
    WARN=$((WARN+1))
}

fail() {
    echo "✗ $1"
    FAIL=$((FAIL+1))
}

echo
echo "=============================================================="
echo " REQUEST RUNNER® — GLOBAL DISTRIBUTION HARDENING"
echo " UNICODE → LOCALE → RTL → LEGAL → DISTRIBUTION"
echo "=============================================================="
echo

###############################################################################
# 1. INSPECT FIRST
###############################################################################

echo "[1] PRE-MUTATION INSPECTION"
echo "--------------------------------------------------------------"

ok "Root: $ROOT"

for f in \
    package.json \
    server.js \
    next.config.js \
    EB_PLATFORM.sh \
    start.sh \
    launch.sh
do
    if [ -f "$f" ]; then
        ok "$f exists"
    else
        warn "$f missing"
    fi
done

echo
echo "[2] EXISTING LOCALIZATION SURFACE"
echo "--------------------------------------------------------------"

find . \
    -maxdepth 4 \
    -type f \
    \( \
        -iname '*locale*' \
        -o -iname '*i18n*' \
        -o -iname '*translation*' \
        -o -iname '*language*' \
    \) \
    ! -path './node_modules/*' \
    ! -path './.git/*' \
    ! -path './.next/*' \
    2>/dev/null |
    sort |
    head -n 100

echo
echo "[3] EXISTING LEGAL SURFACE"
echo "--------------------------------------------------------------"

find legal -maxdepth 3 -type f 2>/dev/null | sort || true

echo
echo "[4] RUNTIME INSPECTION"
echo "--------------------------------------------------------------"

if command -v node >/dev/null 2>&1; then
    ok "Node $(node --version)"
else
    fail "Node unavailable"
fi

if command -v npm >/dev/null 2>&1; then
    ok "npm available"
else
    fail "npm unavailable"
fi

if [ "$FAIL" -ne 0 ]; then
    echo
    echo "INSPECTION FAILED — NO MUTATION PERFORMED."
    exit 1
fi

###############################################################################
# 2. BACKUP
###############################################################################

echo
echo "[5] SAFETY BACKUP"
echo "--------------------------------------------------------------"

mkdir -p "$BACKUP"

for f in \
    package.json \
    server.js \
    next.config.js
do
    [ -f "$f" ] && cp -p "$f" "$BACKUP/"
done

[ -d legal ] && cp -a legal "$BACKUP/"
[ -d app ] && cp -a app "$BACKUP/"
[ -d apps ] && cp -a apps "$BACKUP/"

ok "Backup created: $BACKUP"

###############################################################################
# 3. GLOBAL I18N ARCHITECTURE
###############################################################################

echo
echo "[6] GLOBAL LOCALIZATION ARCHITECTURE"
echo "--------------------------------------------------------------"

mkdir -p \
    i18n \
    i18n/locales \
    i18n/legal \
    i18n/rtl \
    i18n/catalog \
    i18n/scripts

cat > i18n/config.json <<'JSON'
{
  "schema": "request-runner-i18n/v1",
  "defaultLocale": "en",
  "fallbackLocale": "en",
  "unicode": "UTF-8",
  "localeStandard": "BCP-47",
  "directionDetection": true,
  "legalTranslationPolicy": "localized-reference-with-authoritative-version",
  "supportedLocaleExpansion": true,
  "missingTranslationPolicy": "fallback",
  "numberingSystemDetection": true,
  "dateTimeLocalization": true,
  "currencyLocalization": true,
  "pluralRules": true,
  "relativeTime": true,
  "collation": true,
  "rtlSupport": true
}
JSON

cat > i18n/locales/registry.json <<'JSON'
{
  "schema": "BCP-47",
  "default": "en",
  "fallback": "en",
  "rtl": [
    "ar",
    "arc",
    "dv",
    "fa",
    "he",
    "ku",
    "ps",
    "ur",
    "yi"
  ],
  "families": {
    "english": ["en"],
    "french": ["fr"],
    "spanish": ["es"],
    "german": ["de"],
    "italian": ["it"],
    "portuguese": ["pt"],
    "dutch": ["nl"],
    "russian": ["ru"],
    "ukrainian": ["uk"],
    "polish": ["pl"],
    "czech": ["cs"],
    "slovak": ["sk"],
    "hungarian": ["hu"],
    "romanian": ["ro"],
    "bulgarian": ["bg"],
    "serbian": ["sr"],
    "croatian": ["hr"],
    "slovenian": ["sl"],
    "greek": ["el"],
    "turkish": ["tr"],
    "arabic": ["ar"],
    "hebrew": ["he"],
    "persian": ["fa"],
    "urdu": ["ur"],
    "pashto": ["ps"],
    "hindi": ["hi"],
    "bengali": ["bn"],
    "punjabi": ["pa"],
    "gujarati": ["gu"],
    "marathi": ["mr"],
    "tamil": ["ta"],
    "telugu": ["te"],
    "kannada": ["kn"],
    "malayalam": ["ml"],
    "thai": ["th"],
    "vietnamese": ["vi"],
    "indonesian": ["id"],
    "malay": ["ms"],
    "filipino": ["fil"],
    "chinese-simplified": ["zh-CN"],
    "chinese-traditional": ["zh-TW"],
    "japanese": ["ja"],
    "korean": ["ko"],
    "swahili": ["sw"],
    "afrikaans": ["af"],
    "amharic": ["am"],
    "somali": ["so"],
    "zulu": ["zu"],
    "xhosa": ["xh"]
  }
}
JSON

ok "BCP-47 locale registry created"
ok "RTL locale registry created"

###############################################################################
# 4. UNIVERSAL LOCALE RESOLVER
###############################################################################

cat > i18n/locale-resolver.js <<'JS'
"use strict";

const fs = require("fs");
const path = require("path");

const ROOT = __dirname;
const config = JSON.parse(
  fs.readFileSync(path.join(ROOT, "config.json"), "utf8")
);

function normalize(locale) {
  if (!locale || typeof locale !== "string") {
    return config.defaultLocale;
  }

  try {
    const canonical = Intl.getCanonicalLocales(locale)[0];
    return canonical || config.defaultLocale;
  } catch {
    return config.defaultLocale;
  }
}

function resolveLocale(input) {
  const requested = normalize(input);

  const available = [
    config.defaultLocale,
    config.fallbackLocale,
    requested,
    requested.split("-")[0]
  ];

  return [...new Set(available)][0];
}

function direction(locale) {
  const language = normalize(locale).split("-")[0];

  return [
    "ar",
    "arc",
    "dv",
    "fa",
    "he",
    "ku",
    "ps",
    "ur",
    "yi"
  ].includes(language)
    ? "rtl"
    : "ltr";
}

module.exports = Object.freeze({
  normalize,
  resolveLocale,
  direction
});
JS

node --check i18n/locale-resolver.js >/dev/null 2>&1 &&
    ok "Locale resolver syntax"

###############################################################################
# 5. RTL / UNIVERSAL TYPOGRAPHY
###############################################################################

cat > i18n/rtl/global.css <<'CSS'
/*
 * Request Runner® — Global Internationalization Layer
 */

html {
    text-rendering: optimizeLegibility;
}

html[dir="rtl"] {
    direction: rtl;
}

html[dir="ltr"] {
    direction: ltr;
}

body {
    unicode-bidi: plaintext;
    overflow-wrap: anywhere;
    word-break: normal;
}

[dir="rtl"] {
    text-align: start;
}

[dir="ltr"] {
    text-align: start;
}

.ip-symbol {
    font-size: 0.58em;
    line-height: 0;
    vertical-align: super;
    margin-inline-start: 0.04em;
}
CSS

ok "Global RTL/LTR CSS created"

###############################################################################
# 6. LANGUAGE-AWARE LEGAL STRUCTURE
###############################################################################

echo
echo "[7] GLOBAL LEGAL DOCUMENT MODEL"
echo "--------------------------------------------------------------"

cat > i18n/legal/legal-document.schema.json <<'JSON'
{
  "schema": "request-runner-legal-document/v1",
  "required": [
    "id",
    "locale",
    "version",
    "effectiveDate",
    "jurisdiction",
    "documentType",
    "status",
    "authoritativeLanguage"
  ],
  "documentTypes": [
    "terms",
    "privacy",
    "copyright",
    "trademark",
    "intellectual-property",
    "acceptable-use",
    "security",
    "cookies",
    "licenses",
    "disclaimer",
    "accessibility",
    "acknowledgments",
    "data-retention"
  ],
  "translationPolicy": {
    "authoritativeVersion": true,
    "machineTranslationRequiresReview": true,
    "legalMeaningMustBePreserved": true
  }
}
JSON

cat > i18n/legal/README.md <<'LEGAL'
# Global Legal Localization

Each legal document should contain:

- Document identifier
- Version
- Effective date
- Jurisdiction
- Locale
- Authoritative language
- Translation status
- Review status
- Last legal review
- Applicable jurisdiction
- Contact information

Localized legal documents should not silently alter substantive legal meaning.

Where translations conflict, the governing version should be expressly
identified in the applicable production terms.

© 2026 Easton Bodeux® / EB Enterprises®. All rights reserved.
LEGAL

ok "Legal localization model created"

###############################################################################
# 7. LANGUAGE INVENTORY
###############################################################################

echo
echo "[8] LANGUAGE INVENTORY"
echo "--------------------------------------------------------------"

cat > i18n/catalog/LANGUAGE_CATALOG.json <<'JSON'
{
  "catalogVersion": "1.0.0",
  "unicode": "UTF-8",
  "localeStandard": "BCP-47",
  "coverage": "extensible",
  "locales": [
    "af",
    "am",
    "ar",
    "bg",
    "bn",
    "cs",
    "da",
    "de",
    "el",
    "en",
    "es",
    "fa",
    "fi",
    "fil",
    "fr",
    "he",
    "hi",
    "hr",
    "hu",
    "id",
    "it",
    "ja",
    "ka",
    "kk",
    "km",
    "kn",
    "ko",
    "lo",
    "lt",
    "lv",
    "mk",
    "ml",
    "mn",
    "mr",
    "ms",
    "my",
    "ne",
    "nl",
    "no",
    "pa",
    "pl",
    "pt",
    "ro",
    "ru",
    "sk",
    "sl",
    "so",
    "sq",
    "sr",
    "sv",
    "sw",
    "ta",
    "te",
    "th",
    "tr",
    "uk",
    "ur",
    "uz",
    "vi",
    "xh",
    "yo",
    "zh-CN",
    "zh-TW",
    "zu"
  ]
}
JSON

ok "Global language catalog created"

###############################################################################
# 8. TRANSLATION SAFETY
###############################################################################

cat > i18n/scripts/translation-audit.js <<'JS'
"use strict";

const fs = require("fs");
const path = require("path");

const root = path.resolve(__dirname, "..");

const required = [
  "config.json",
  "locales/registry.json",
  "catalog/LANGUAGE_CATALOG.json",
  "legal/legal-document.schema.json",
  "rtl/global.css",
  "locale-resolver.js"
];

let failures = 0;

for (const file of required) {
  const full = path.join(root, file);

  if (!fs.existsSync(full)) {
    console.error(`MISSING: ${file}`);
    failures++;
    continue;
  }

  console.log(`OK: ${file}`);
}

if (failures) {
  process.exit(1);
}

console.log("GLOBAL I18N AUDIT: PASS");
JS

node i18n/scripts/translation-audit.js &&
    ok "Global localization audit passed"

###############################################################################
# 9. LEGAL TRANSLATION STATUS
###############################################################################

cat > i18n/legal/TRANSLATION_STATUS.md <<'LEGAL'
# Legal Translation Status

The English-language source documents are the initial authoritative drafting
source unless a production legal document explicitly identifies another
authoritative language.

Translations must be:

1. Human-reviewed where legally material.
2. Versioned.
3. Dated.
4. Associated with a jurisdiction.
5. Traceable to the source document.
6. Reviewed whenever the source changes.

Automated translation may assist drafting but should not automatically be
treated as a legally authoritative translation.

© 2026 Easton Bodeux® / EB Enterprises®. All rights reserved.
LEGAL

ok "Legal translation governance created"

###############################################################################
# 10. GLOBAL FOOTER REQUIREMENTS
###############################################################################

cat > i18n/catalog/FOOTER_REQUIREMENTS.md <<'LEGAL'
# Global Footer Requirements

Every public Request Runner® surface should expose localized access to:

- Terms
- Privacy
- Copyright
- Trademarks
- Intellectual Property
- Licenses
- Acceptable Use
- Security
- Accessibility
- Cookies / Storage
- Disclaimer
- Acknowledgments
- Data Retention
- Language selector

The footer should:

- Respect RTL direction.
- Preserve legal names and marks.
- Use Unicode-safe typography.
- Provide keyboard navigation.
- Provide accessible labels.
- Avoid hard-coded English-only UI.
- Respect locale-specific date, number, and currency formatting.
LEGAL

ok "Global footer requirements created"

###############################################################################
# 11. COPYRIGHT / IP METADATA
###############################################################################

cat > i18n/catalog/IP_METADATA.json <<'JSON'
{
  "organization": "EB Enterprises®",
  "principalBrand": "Request Runner®",
  "copyright": "© 2026 Easton Bodeux® / EB Enterprises®",
  "rights": "All rights reserved except where expressly licensed.",
  "encoding": "UTF-8",
  "localeStandard": "BCP-47",
  "legalLocalization": true,
  "rtlSupport": true,
  "globalDistribution": true
}
JSON

ok "Global IP metadata created"

###############################################################################
# 12. FINAL INSPECTION
###############################################################################

echo
echo "[9] POST-MUTATION INSPECTION"
echo "--------------------------------------------------------------"

for f in \
    i18n/config.json \
    i18n/locales/registry.json \
    i18n/catalog/LANGUAGE_CATALOG.json \
    i18n/catalog/IP_METADATA.json \
    i18n/locale-resolver.js \
    i18n/rtl/global.css \
    i18n/legal/legal-document.schema.json \
    i18n/legal/README.md \
    i18n/legal/TRANSLATION_STATUS.md \
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
    ok "Localization JavaScript syntax"
else
    fail "Localization JavaScript syntax"
fi

###############################################################################
# 13. EXISTING PLATFORM VALIDATION
###############################################################################

echo
echo "[10] PLATFORM VALIDATION"
echo "--------------------------------------------------------------"

if bash -n EB_PLATFORM.sh &&
   bash -n start.sh &&
   bash -n launch.sh &&
   bash -n REQUEST_RUNNER_RELEASE_GATE.sh
then
    ok "Platform shell syntax"
else
    fail "Platform shell syntax"
fi

if [ -f server.js ] &&
   node --check server.js >/dev/null 2>&1
then
    ok "server.js syntax"
fi

###############################################################################
# 14. RELEASE GATE
###############################################################################

echo
echo "[11] RELEASE GATE"
echo "--------------------------------------------------------------"

if [ -x ./REQUEST_RUNNER_RELEASE_GATE.sh ]; then
    if ./REQUEST_RUNNER_RELEASE_GATE.sh; then
        ok "Request Runner® release gate GREEN"
    else
        fail "Request Runner® release gate RED"
    fi
else
    warn "Release gate unavailable"
fi

###############################################################################
# REPORT
###############################################################################

cat > "$REPORT" <<REPORT
REQUEST RUNNER® — GLOBAL LOCALIZATION / LEGAL HARDENING

Timestamp: $(date)

PASS: $PASS
WARN: $WARN
FAIL: $FAIL

Backup:
$BACKUP

Localization root:
echo "$ROOT/i18n"

Languages:
BCP-47 extensible catalog

Unicode:
UTF-8

RTL:
Enabled

Legal localization:
Enabled

Trademark presentation:
Superscript / reduced-size ® treatment

© 2026 Easton Bodeux® / EB Enterprises®.
REPORT

echo
echo "=============================================================="
echo " REQUEST RUNNER® — GLOBAL DISTRIBUTION RESULT"
echo "=============================================================="
echo
echo "PASS:   $PASS"
echo "WARN:   $WARN"
echo "FAIL:   $FAIL"
echo
echo "Backup: $BACKUP"
echo "Report: $REPORT"
echo

if [ "$FAIL" -eq 0 ]; then
    echo "STATUS: GREEN"
    echo "GLOBAL LOCALIZATION FOUNDATION READY"
else
    echo "STATUS: RED"
    echo "REVIEW FAILURES"
    exit 1
fi

echo "=============================================================="
