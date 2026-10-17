const { execSync } = require('child_process');
const fs = require('fs');

console.log("[+] Checking environment for Bubblewrap TWA APK compilation...");

try {
    // Check if bubblewrap is installed globally
    execSync('bubblewrap --version', { stdio: 'ignore' });
    console.log("[+] Bubblewrap CLI detected.");
} catch (e) {
    console.log("[+] Installing Bubblewrap CLI...");
    try {
        execSync('npm install -g @bubblewrap/cli', { stdio: 'inherit' });
    } catch (err) {
        console.log("[-] Global npm install requires permissions or environment setup. Setting up local TWA config instead...");
    }
}

// Create automated Bubblewrap configuration twa-manifest.json
const twaManifest = {
  "host": "127.0.0.1:51201",
  "name": "EB Sales Tracker",
  "short_name": "SalesTracker",
  "start_url": "/",
  "display": "standalone",
  "theme_color": "#0b0f19",
  "background_color": "#0b0f19",
  "navigation_color": "#0b0f19",
  "navigation_color_dark": "#0b0f19",
  "navigation_divider_color": "#0b0f19",
  "navigation_divider_color_dark": "#0b0f19",
  "splash_screen_background_color": "#0b0f19",
  "iconUrl": "http://127.0.0.1:51201/icon.png",
  "maskableIconUrl": "http://127.0.0.1:51201/icon.png",
  "appId": "com.ebenterprises.salestracker",
  "appName": "EB Sales Tracker",
  "launcherName": "Sales Tracker",
  "versionName": "1.0.0",
  "versionCode": 1,
  "signingKey": {
    "path": "./android.keystore",
    "alias": "android"
  },
  "generatorApp": "Bubblewrap CLI",
  "useBrowserChoices": true,
  "features": {},
  "alphaDependencies": {
    "enabled": false
  },
  "enableCordova": false,
  "shortcuts": [],
  "shareTarget": {}
};

fs.writeFileSync('twa-manifest.json', JSON.stringify(twaManifest, null, 2));
console.log("[+] TWA Manifest generated successfully.");
console.log("[+] Ready to compile APK package.");
