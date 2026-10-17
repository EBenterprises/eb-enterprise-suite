const fs = require('fs');

console.log("[+] Generating APK compilation assets & TWA wrapper guide...");

// Create a Digital Asset Links configuration template (assetlinks.json) for TWA packaging
const assetLinks = [
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "com.ebenterprises.salestracker",
      "sha256_cert_fingerprints": [
        "YOUR_RELEASE_KEY_SHA256_FINGERPRINT_HERE"
      ]
    }
  }
];

if (!fs.existsSync('android')) {
    fs.mkdirSync('android');
}
fs.writeFileSync('android/assetlinks.json', JSON.stringify(assetLinks, null, 2));

console.log("[+] Asset Links template created at android/assetlinks.json");
