#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

STAMP="$(date '+%Y%m%d-%H%M%S')"
BACKUP="$ROOT/.legal-backup-$STAMP"
REPORT="$ROOT/.legal-audit-$STAMP.txt"

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
echo " REQUEST RUNNER® — LEGAL / IP HARDENING"
echo " INSPECT → BACKUP → REPAIR → VERIFY"
echo "=============================================================="
echo

###############################################################################
# 1. PRE-MUTATION INSPECTION
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
echo "[2] EXISTING LEGAL / IP SURFACE"
echo "--------------------------------------------------------------"

LEGAL_MATCHES="$(
    grep -RIl \
        --exclude-dir=node_modules \
        --exclude-dir=.git \
        --exclude-dir=.next \
        -E \
        'copyright|privacy|terms|conditions|trademark|legal|acknowledg|intellectual property|license' \
        . 2>/dev/null | head -n 80 || true
)"

if [ -n "$LEGAL_MATCHES" ]; then
    echo "$LEGAL_MATCHES"
else
    warn "No centralized legal surface detected"
fi

echo
echo "[3] REGISTERED SYMBOL INSPECTION"
echo "--------------------------------------------------------------"

REGISTERED_COUNT="$(
    grep -Roh \
        --exclude-dir=node_modules \
        --exclude-dir=.git \
        --exclude-dir=.next \
        '®' . 2>/dev/null |
        wc -l |
        tr -d ' ' || true
)"

echo "Registered symbols detected: ${REGISTERED_COUNT:-0}"

echo
echo "[4] APPLICATION STRUCTURE"
echo "--------------------------------------------------------------"

find . \
    -maxdepth 3 \
    -type f \
    ! -path './node_modules/*' \
    ! -path './.git/*' \
    ! -path './.next/*' \
    2>/dev/null |
    sort |
    head -n 120

echo
echo "[5] SYNTAX INSPECTION"
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

for f in \
    server.js \
    framework/index.js
do
    if [ -f "$f" ] && node --check "$f" >/dev/null 2>&1; then
        ok "$f syntax"
    elif [ -f "$f" ]; then
        fail "$f syntax"
    fi
done

if [ "$FAIL" -ne 0 ]; then
    echo
    echo "PRE-MUTATION INSPECTION FAILED."
    echo "NO FILES WERE MODIFIED."
    exit 1
fi

###############################################################################
# 2. SAFETY BACKUP
###############################################################################

echo
echo "[6] SAFETY BACKUP"
echo "--------------------------------------------------------------"

mkdir -p "$BACKUP"

cp -a \
    package.json \
    server.js \
    next.config.js \
    EB_PLATFORM.sh \
    start.sh \
    launch.sh \
    "$BACKUP/" 2>/dev/null || true

[ -d framework ] && cp -a framework "$BACKUP/" 2>/dev/null || true
[ -d apps ] && cp -a apps "$BACKUP/" 2>/dev/null || true

ok "Backup created: $BACKUP"

###############################################################################
# 3. LEGAL DIRECTORY
###############################################################################

echo
echo "[7] LEGAL / IP FRAMEWORK"
echo "--------------------------------------------------------------"

mkdir -p \
    legal \
    legal/policies \
    legal/notices \
    legal/licenses \
    legal/acknowledgments

cat > legal/LEGAL_INDEX.md <<'LEGAL'
# REQUEST RUNNER® — Legal & Intellectual Property Framework

© 2026 Easton Bodeux® / EB Enterprises®.

All rights reserved except where expressly stated otherwise.

This directory contains the authoritative legal-notice framework for
Request Runner® and associated software, services, interfaces, documentation,
designs, trademarks, copyrights, inventions, and intellectual property.

## Policies

- Copyright
- Terms of Use
- Terms and Conditions
- Privacy Policy
- Cookie / Storage Notice
- Acceptable Use Policy
- Security Notice
- Intellectual Property Notice
- Trademark Notice
- Disclaimer
- Licensing Notice
- Third-Party Software Notice
- Open Source Acknowledgments
- Accessibility Notice
- Service Availability Notice
- Data Retention Notice
- Communications Notice

## Important

Nothing in this framework is intended to create legal rights beyond those
provided by applicable law.

Jurisdiction-specific provisions should be reviewed and finalized by qualified
legal counsel before publication or commercial deployment.

© 2026 Easton Bodeux®. All rights reserved.
LEGAL

cat > legal/policies/COPYRIGHT.md <<'LEGAL'
# Copyright Notice

© 2026 Easton Bodeux® / EB Enterprises®.

All rights reserved except where expressly licensed.

The software, source code, object code, interfaces, layouts, documentation,
graphics, designs, workflows, databases, schemas, architecture, content,
branding, audiovisual material, and other original materials comprising
Request Runner® are protected by applicable copyright and intellectual
property laws.

No copying, reproduction, redistribution, publication, modification,
commercial exploitation, or creation of derivative works is permitted except
as expressly authorized by the applicable license or written permission.

Third-party materials remain subject to their respective owners' rights and
licenses.

© 2026 Easton Bodeux®. All rights reserved.
LEGAL

cat > legal/policies/TERMS.md <<'LEGAL'
# Terms of Use

By accessing or using Request Runner®, you agree to comply with applicable
law and the rules published with the service.

You may not use the service to violate applicable law, interfere with service
operation, circumvent security controls, abuse authentication systems,
misappropriate intellectual property, or compromise other users or systems.

Service features may change, be suspended, or be discontinued where permitted
by applicable law.

These terms should be reviewed and supplemented with jurisdiction-specific
provisions before publication.

© 2026 Easton Bodeux®. All rights reserved.
LEGAL

cat > legal/policies/TERMS_AND_CONDITIONS.md <<'LEGAL'
# Terms and Conditions

These Terms and Conditions govern access to and use of Request Runner®,
including associated applications, APIs, websites, services, documentation,
and related products.

Users are responsible for maintaining the confidentiality of credentials and
for activity performed through their authorized accounts.

Nothing in these terms limits rights that cannot lawfully be excluded under
applicable law.

Additional commercial, subscription, payment, refund, warranty, limitation
of liability, dispute resolution, governing-law, and termination provisions
should be reviewed by qualified counsel before production publication.

© 2026 Easton Bodeux®. All rights reserved.
LEGAL

cat > legal/policies/PRIVACY.md <<'LEGAL'
# Privacy Policy Framework

Request Runner® should collect, use, retain, disclose, and protect personal
information only for legitimate and disclosed purposes and in accordance with
applicable privacy law.

The production privacy policy should identify:

- Information collected
- Sources of information
- Purposes of processing
- Legal bases where applicable
- Cookies and local storage
- Analytics
- Service providers
- Data retention
- Security safeguards
- International transfers
- User rights
- Access and correction procedures
- Deletion procedures
- Contact information
- Children's privacy
- Policy changes

This document is a framework and must be completed with the actual data flows
and applicable jurisdictional requirements before publication.

© 2026 Easton Bodeux®. All rights reserved.
LEGAL

cat > legal/policies/INTELLECTUAL_PROPERTY.md <<'LEGAL'
# Intellectual Property Notice

Request Runner® and associated original architecture, software, interfaces,
documentation, visual designs, workflows, naming systems, inventions,
processes, specifications, and related materials constitute intellectual
property of their respective owners.

Unauthorized use, reproduction, extraction, reverse engineering where
prohibited by law, or commercial exploitation is not permitted except under
an applicable license or written authorization.

Patent rights, if any, exist only to the extent established by applicable
patent filings or granted patents. This notice does not itself create a patent
right.

© 2026 Easton Bodeux®. All rights reserved.
LEGAL

cat > legal/policies/TRADEMARKS.md <<'LEGAL'
# Trademark Notice

REQUEST RUNNER® and other marks identified with ® or ™ are used as
trademarks, service marks, or proprietary brand identifiers of their
respective owners.

The ® symbol should only be used where the corresponding mark is registered
in the relevant jurisdiction.

Third-party marks remain the property of their respective owners.

No trademark license is granted merely by reference to a mark within the
software, documentation, website, or service.

© 2026 Easton Bodeux®. All rights reserved.
LEGAL

cat > legal/policies/DISCLAIMER.md <<'LEGAL'
# Disclaimer

The service is provided subject to applicable law and the terms governing its
use.

To the maximum extent permitted by applicable law, no representation is made
that the service will be uninterrupted, error-free, secure, or available at
all times.

Nothing in this disclaimer excludes warranties, rights, or remedies that
cannot legally be excluded.

© 2026 Easton Bodeux®. All rights reserved.
LEGAL

cat > legal/policies/ACCEPTABLE_USE.md <<'LEGAL'
# Acceptable Use Policy

Users must not:

- Violate applicable law
- Infringe intellectual property rights
- Circumvent security controls
- Introduce malicious software
- Abuse APIs or infrastructure
- Attempt unauthorized access
- Interfere with service availability
- Conduct fraudulent activity
- Misrepresent identity or authorization
- Use the service to facilitate prohibited activity

Additional product-specific restrictions may apply.

© 2026 Easton Bodeux®. All rights reserved.
LEGAL

cat > legal/policies/SECURITY.md <<'LEGAL'
# Security Notice

Security issues should be reported through the designated security contact.

Do not publicly disclose exploitable vulnerabilities before a reasonable
opportunity for remediation has been provided.

Production deployments should document authentication, authorization,
secrets management, encryption, logging, monitoring, backups, incident
response, dependency management, and vulnerability handling.

© 2026 Easton Bodeux®. All rights reserved.
LEGAL

cat > legal/policies/COOKIES_AND_STORAGE.md <<'LEGAL'
# Cookies and Storage Notice

Request Runner® may use browser storage, cookies, session identifiers, or
similar technologies where required for authentication, functionality,
security, preferences, analytics, or other disclosed purposes.

The production notice must accurately reflect the technologies actually
deployed.

© 2026 Easton Bodeux®. All rights reserved.
LEGAL

cat > legal/policies/LICENSING.md <<'LEGAL'
# Licensing Notice

Unless a specific file or component expressly states otherwise, no license to
copy, modify, distribute, sublicense, or commercially exploit proprietary
Request Runner® materials is granted by publication or access.

Third-party components remain governed by their respective licenses.

© 2026 Easton Bodeux®. All rights reserved.
LEGAL

cat > legal/policies/THIRD_PARTY.md <<'LEGAL'
# Third-Party Software Notice

Request Runner® may incorporate third-party libraries, frameworks, runtimes,
services, fonts, icons, or other components.

Those components remain subject to their respective licenses and notices.

Applicable third-party license texts should be maintained in
legal/licenses/.

© 2026 Easton Bodeux®. All rights reserved.
LEGAL

cat > legal/policies/ACKNOWLEDGMENTS.md <<'LEGAL'
# Acknowledgments

Request Runner® acknowledges the open-source communities, standards bodies,
software authors, maintainers, and third-party projects that make modern
software development possible.

Specific dependencies and their licenses should be enumerated from the
production dependency tree before release.

Third-party acknowledgment does not imply ownership of third-party materials.

© 2026 Easton Bodeux®. All rights reserved.
LEGAL

cat > legal/policies/ACCESSIBILITY.md <<'LEGAL'
# Accessibility Notice

Request Runner® is intended to provide an accessible user experience.

Production accessibility commitments should identify supported standards,
assistive technologies, contact procedures, and known limitations.

© 2026 Easton Bodeux®. All rights reserved.
LEGAL

cat > legal/policies/DATA_RETENTION.md <<'LEGAL'
# Data Retention Notice

Production retention periods should be defined according to the actual data
processed, contractual requirements, security requirements, and applicable
law.

Data should not be retained longer than necessary for the disclosed purpose
unless a lawful basis requires otherwise.

© 2026 Easton Bodeux®. All rights reserved.
LEGAL

###############################################################################
# 4. REGISTERED-SYMBOL PRESENTATION
###############################################################################

echo
echo "[8] REGISTERED SYMBOL PRESENTATION"
echo "--------------------------------------------------------------"

mkdir -p legal/ui

cat > legal/ui/ip-symbol.css <<'CSS'
/*
 * Request Runner® — Proprietary IP Presentation
 *
 * The registered-symbol treatment is visual only.
 * Legal registration status is determined independently by jurisdiction.
 */

.ip-symbol {
    display: inline-block;
    font-size: 0.58em;
    line-height: 0;
    vertical-align: super;
    position: relative;
    top: -0.05em;
    margin-left: 0.04em;
    font-weight: inherit;
    text-decoration: none;
}

.ip-trademark {
    display: inline-block;
    font-size: 0.58em;
    line-height: 0;
    vertical-align: super;
    position: relative;
    top: -0.05em;
    margin-left: 0.04em;
    font-weight: inherit;
    text-decoration: none;
}
CSS

cat > legal/ui/ip-symbol.js <<'JS'
/*
 * Request Runner® — Registered Symbol Normalizer
 *
 * Converts a standalone ® into a visually smaller superscript symbol
 * without changing the underlying legal text.
 */

(function () {
  "use strict";

  function normalizeRegisteredSymbols(root) {
    const scope = root || document;

    const walker = document.createTreeWalker(
      scope,
      NodeFilter.SHOW_TEXT
    );

    const nodes = [];

    while (walker.nextNode()) {
      const node = walker.currentNode;

      if (
        node.parentElement &&
        !node.parentElement.closest(
          "script,style,textarea,input,[data-ip-normalized]"
        ) &&
        node.nodeValue &&
        node.nodeValue.includes("®")
      ) {
        nodes.push(node);
      }
    }

    for (const node of nodes) {
      const parts = node.nodeValue.split("®");

      if (parts.length < 2) continue;

      const fragment = document.createDocumentFragment();

      parts.forEach((part, index) => {
        if (part) {
          fragment.appendChild(document.createTextNode(part));
        }

        if (index < parts.length - 1) {
          const symbol = document.createElement("sup");
          symbol.className = "ip-symbol";
          symbol.textContent = "®";
          symbol.setAttribute("aria-label", "registered trademark symbol");
          fragment.appendChild(symbol);
        }
      });

      const parent = node.parentNode;

      if (parent) {
        parent.replaceChild(fragment, node);
      }
    }
  }

  if (document.readyState === "loading") {
    document.addEventListener(
      "DOMContentLoaded",
      () => normalizeRegisteredSymbols()
    );
  } else {
    normalizeRegisteredSymbols();
  }

  window.RequestRunnerIP = Object.freeze({
    normalizeRegisteredSymbols
  });
})();
JS

ok "Registered-symbol CSS created"
ok "Registered-symbol normalizer created"

###############################################################################
# 5. CENTRAL LEGAL NOTICE
###############################################################################

cat > legal/notices/NOTICE.md <<'LEGAL'
# REQUEST RUNNER® — MASTER LEGAL NOTICE

© 2026 Easton Bodeux® / EB Enterprises®. All rights reserved except where
expressly licensed.

Request Runner®, associated names, logos, interfaces, software, architecture,
documentation, designs, workflows, and original materials may constitute
copyright, trademark, trade-secret, patent, or other intellectual property.

Use of the service does not transfer ownership of intellectual property.

Third-party names, marks, software, and materials remain the property of
their respective owners and are governed by applicable terms and licenses.

For authoritative obligations, consult the applicable Terms, Privacy Policy,
Licensing Notice, Intellectual Property Notice, and other policies published
for the specific production service.

© 2026 Easton Bodeux®. All rights reserved.
LEGAL

###############################################################################
# 6. AUTOMATIC DEPENDENCY ACKNOWLEDGMENT INVENTORY
###############################################################################

echo
echo "[9] DEPENDENCY ACKNOWLEDGMENT INVENTORY"
echo "--------------------------------------------------------------"

if [ -f package.json ]; then
    node - <<'NODE' > legal/acknowledgments/DEPENDENCIES.txt
const fs = require("fs");

const pkg = JSON.parse(fs.readFileSync("package.json", "utf8"));

console.log("REQUEST RUNNER® — DEPENDENCY INVENTORY");
console.log("");
console.log("Dependencies:");

for (const [name, version] of Object.entries(pkg.dependencies || {})) {
  console.log(`- ${name}: ${version}`);
}

console.log("");
console.log("Development dependencies:");

for (const [name, version] of Object.entries(pkg.devDependencies || {})) {
  console.log(`- ${name}: ${version}`);
}
NODE

    ok "Dependency inventory generated"
else
    warn "package.json unavailable; dependency inventory skipped"
fi

###############################################################################
# 7. LEGAL ROUTE MANIFEST
###############################################################################

cat > legal/ROUTES.md <<'LEGAL'
# Legal Route Manifest

Recommended public routes:

- /legal
- /legal/terms
- /legal/privacy
- /legal/copyright
- /legal/trademarks
- /legal/intellectual-property
- /legal/licenses
- /legal/acceptable-use
- /legal/security
- /legal/acknowledgments
- /legal/accessibility
- /legal/disclaimer
- /legal/cookies
- /legal/data-retention

The application should expose these routes through its canonical legal footer
or legal center.

© 2026 Easton Bodeux®. All rights reserved.
LEGAL

ok "Legal route manifest created"

###############################################################################
# 8. MASTER FOOTER COPY
###############################################################################

cat > legal/notices/FOOTER.md <<'LEGAL'
© 2026 Easton Bodeux® / EB Enterprises®. All rights reserved.

Request Runner® and associated names, logos, software, designs, documentation,
and original materials are protected by applicable intellectual-property
laws.

Terms · Privacy · Copyright · Trademarks · Intellectual Property · Licenses ·
Acceptable Use · Security · Accessibility · Disclaimer · Acknowledgments

Third-party trademarks and software remain the property of their respective
owners.
LEGAL

ok "Master legal footer created"

###############################################################################
# 9. POST-MUTATION VERIFICATION
###############################################################################

echo
echo "[10] POST-MUTATION VERIFICATION"
echo "--------------------------------------------------------------"

for f in \
    legal/LEGAL_INDEX.md \
    legal/notices/NOTICE.md \
    legal/notices/FOOTER.md \
    legal/policies/COPYRIGHT.md \
    legal/policies/TERMS.md \
    legal/policies/TERMS_AND_CONDITIONS.md \
    legal/policies/PRIVACY.md \
    legal/policies/INTELLECTUAL_PROPERTY.md \
    legal/policies/TRADEMARKS.md \
    legal/policies/DISCLAIMER.md \
    legal/policies/ACCEPTABLE_USE.md \
    legal/policies/SECURITY.md \
    legal/policies/COOKIES_AND_STORAGE.md \
    legal/policies/LICENSING.md \
    legal/policies/THIRD_PARTY.md \
    legal/policies/ACKNOWLEDGMENTS.md \
    legal/policies/ACCESSIBILITY.md \
    legal/policies/DATA_RETENTION.md \
    legal/ui/ip-symbol.css \
    legal/ui/ip-symbol.js
do
    if [ -s "$f" ]; then
        ok "$f"
    else
        fail "$f"
    fi
done

if node --check legal/ui/ip-symbol.js >/dev/null 2>&1; then
    ok "ip-symbol.js syntax"
else
    fail "ip-symbol.js syntax"
fi

if bash -n EB_PLATFORM.sh &&
   bash -n start.sh &&
   bash -n launch.sh &&
   bash -n REQUEST_RUNNER_RELEASE_GATE.sh
then
    ok "Platform shell syntax"
else
    fail "Platform shell syntax"
fi

if [ -f server.js ] && node --check server.js >/dev/null 2>&1; then
    ok "server.js syntax"
fi

###############################################################################
# 10. RELEASE GATE
###############################################################################

echo
echo "[11] REQUEST RUNNER® RELEASE GATE"
echo "--------------------------------------------------------------"

if [ -x ./REQUEST_RUNNER_RELEASE_GATE.sh ]; then
    if ./REQUEST_RUNNER_RELEASE_GATE.sh; then
        ok "Release gate GREEN"
    else
        fail "Release gate RED"
    fi
else
    warn "Release gate unavailable"
fi

###############################################################################
# RESULT
###############################################################################

cat > "$REPORT" <<REPORT
REQUEST RUNNER® — LEGAL / IP HARDENING REPORT

Timestamp: $(date)
Root: $ROOT

PASS: $PASS
WARN: $WARN
FAIL: $FAIL

Backup:
$BACKUP

Legal framework:
$ROOT/legal

Registered symbol presentation:
$ROOT/legal/ui/ip-symbol.css
$ROOT/legal/ui/ip-symbol.js

© 2026 Easton Bodeux® / EB Enterprises®.
REPORT

echo
echo "=============================================================="
echo " REQUEST RUNNER® — LEGAL / IP HARDENING RESULT"
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
    echo "LEGAL/IP FRAMEWORK INSTALLED"
else
    echo "STATUS: RED"
    echo "REVIEW FAILURES BEFORE RELEASE"
    exit 1
fi

echo "=============================================================="
