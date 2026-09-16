#!/usr/bin/env bash
set -e

echo "[DEPLOY] Initializing EggFinder® Edge Mesh Production Deployment..."

# 1. Inject PWA meta tags into HTML files if not already present
for file in public/index.html public/dashboard.html public/admin.html; do
    if ! grep -q "manifest.json" "$file"; then
        sed -i '/<\/head>/i \    <link rel="manifest" href="/manifest.json">\n    <meta name="theme-color" content="#00ffea">' "$file"
        echo "[DEPLOY] Injected PWA headers into $file"
    fi
done

# 2. Register Service Worker in client index
if ! grep -q "navigator.serviceWorker" public/index.html; then
    sed -i '/<\/script>/i \    if ("serviceWorker" in navigator) { navigator.serviceWorker.register("/sw.js").then(() => console.log("[PWA] Service Worker registered.")); }' public/index.html
    echo "[DEPLOY] Registered service worker bootstrap in consumer portal."
fi

# 3. Trigger scale and verification
./scale_mesh.sh
node benchmark.js

echo ""
echo "======================================================================"
echo "🚀 EGG-FINDER® PRODUCTION MESH LIVE DEPLOYMENT COMPLETE"
echo "======================================================================"
echo "  • Global Gateway      : http://localhost:3000"
echo "  • Command Center      : http://localhost:3000/dashboard.html"
echo "  • Producer Provision  : http://localhost:3000/admin.html"
echo "  • PWA Support         : Active (Manifest + Service Worker Cached)"
echo "======================================================================"
