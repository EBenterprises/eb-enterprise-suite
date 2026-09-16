#!/data/data/com.termux/files/usr/bin/bash
set -e

APP="$HOME/request-runner"
cd "$APP"

echo "=== Request Runner® HMR / Android Final Cleanup ==="

# Back up next.config.js before modifying it
if [ -f next.config.js ]; then
    cp -f next.config.js \
        "next.config.js.backup-$(date +%Y%m%d-%H%M%S)"
fi

# Create/update Next.js configuration safely.
cat > next.config.js <<'CONFIG'
/** @type {import('next').NextConfig} */
const nextConfig = {
  allowedDevOrigins: [
    "127.0.0.1",
    "localhost",
    "192.168.1.188"
  ]
};

module.exports = nextConfig;
CONFIG

echo
echo "✓ allowedDevOrigins configured"
echo "✓ 127.0.0.1 allowed"
echo "✓ localhost allowed"
echo "✓ LAN address allowed"

# Validate that Node can load the configuration.
node - <<'NODE'
const config = require("./next.config.js");

if (!Array.isArray(config.allowedDevOrigins)) {
    throw new Error("allowedDevOrigins is missing");
}

console.log("Allowed development origins:");
for (const origin of config.allowedDevOrigins) {
    console.log("  ✓ " + origin);
}
NODE

echo
echo "Configuration:"
cat next.config.js

echo
echo "================================================"
echo " HMR CLEANUP COMPLETE"
echo "================================================"
echo
echo "Start Request Runner®:"
echo
echo "  ~/request-runner/run-request-runner.sh"
echo
