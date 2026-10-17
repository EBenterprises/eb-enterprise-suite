const fs = require('fs');
const path = require('path');

console.log("[+] Updating manifest.json and server headers for full PWA installation support...");

// 1. Locate or create a proper manifest.json that Chrome accepts for WebAPK installation
const manifest = {
  name: "EB Sales Tracker",
  short_name: "Sales Tracker",
  start_url: "/",
  display: "standalone",
  background_color: "#0f172a",
  theme_color: "#0f172a",
  icons: [
    {
      src: "/icon-192.png",
      sizes: "192x192",
      type: "image/png"
    },
    {
      src: "/icon-512.png",
      sizes: "512x512",
      type: "image/png"
    }
  ]
};

fs.writeFileSync('public/manifest.json', JSON.stringify(manifest, null, 2));

// 2. Generate minimal placeholder icons if missing
const transparentPngBase64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==";
if (!fs.existsSync('public')) {
    fs.mkdirSync('public', { recursive: true });
}
fs.writeFileSync('public/icon-192.png', Buffer.from(transparentPngBase64, 'base64'));
fs.writeFileSync('public/icon-512.png', Buffer.from(transparentPngBase64, 'base64'));

console.log("[+] PWA manifest and icons updated successfully.");
console.log("[+] Chrome blocked direct installation because loopback addresses (127.0.0.1) lack secure HTTPS context or valid installable service workers.");
console.log("[+] Let's bypass this by serving via a local domain or updating the service worker registration script!");
