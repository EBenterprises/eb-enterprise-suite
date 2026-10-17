const fs = require('fs');
const path = require('path');

// Bubblewrap looks for an existing JDK path or config in twa-manifest.json or a local settings file.
// Let's update twa-manifest.json or create the jdkPath property so it doesn't prompt for interactive input!
const manifestPath = path.join(__dirname, 'twa-manifest.json');
if (fs.existsSync(manifestPath)) {
    let manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
    
    // Point directly to system Java home
    manifest.jdkPath = '/data/data/com.termux/files/usr';
    manifest.androidSdkPath = '/data/data/com.termux/files/usr';
    
    fs.writeFileSync(manifestPath, JSON.stringify(manifest, null, 2));
    console.log("[+] Updated twa-manifest.json with explicit jdkPath.");
}

// Also check Bubblewrap global config if it exists in home directory
const homeDir = process.env.HOME || '/data/data/com.termux/files/home';
const configPath = path.join(homeDir, '.bubblewrap', 'config.json');
const configDir = path.dirname(configPath);
if (!fs.existsSync(configDir)) {
    fs.mkdirSync(configDir, { recursive: true });
}

const config = {
    jdkPath: '/data/data/com.termux/files/usr',
    androidSdkPath: '/data/data/com.termux/files/usr'
};
fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
console.log("[+] Bubblewrap global config written.");
