#!/data/data/com.termux/files/usr/bin/bash
set -u

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT" || exit 1

echo "=============================================================="
echo " COMPLETION ENGINE® — BUILD POLICY INSTALL"
echo "=============================================================="

node <<'NODE'
const fs = require("fs");

const file = "package.json";
const pkg = JSON.parse(fs.readFileSync(file, "utf8"));

if (!pkg.scripts) pkg.scripts = {};

/*
 * Android/ARM64 Termux production policy:
 *
 * Next.js 16 defaults to Turbopack, but native Turbopack
 * bindings are unavailable on this platform.
 *
 * Webpack is the verified production path.
 */
pkg.scripts.build = "next build --webpack";

fs.writeFileSync(file, JSON.stringify(pkg, null, 2) + "\n");

console.log("✓ Production build pinned to Android-compatible Webpack");
NODE

cat > .completion-build-policy <<'POLICY'
# COMPLETION ENGINE® BUILD POLICY

PLATFORM=android
ARCH=arm64
NEXT_BUILD_ENGINE=webpack
NEXT_BUILD_COMMAND=next build --webpack

# Turbopack requires native bindings unavailable in this environment.
TURBOPACK=disabled

# Webpack cache snapshot warnings are non-fatal.
WEBPACK_CACHE_WARNINGS=nonfatal

# Required production artifacts.
VERIFY_NEXT_DIRECTORY=true
VERIFY_NEXT_SERVER=true
VERIFY_PAGES_MANIFEST=true
VERIFY_BUILD_EXIT=0
POLICY

echo
echo "Installed:"
cat .completion-build-policy

echo
echo "=============================================================="
echo " COMPLETION ENGINE® — POLICY READY"
echo "=============================================================="
echo "Verified engine: Webpack"
echo "Turbopack:       Disabled"
echo "Manifest check:  Required"
echo "Cache warnings:  Non-fatal"
echo "=============================================================="
