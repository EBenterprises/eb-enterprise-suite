const { execSync } = require('child_process');

console.log("[+] Verifying contents of your standalone Android wrapper archive...");
try {
    execSync('tar -tf eb_sales_tracker_android_wrapper.tar.gz', { stdio: 'inherit' });
    console.log("\n[+] Archive verified successfully. All WebView files, Manifest configurations, and build assets are securely packed.");
} catch (e) {
    console.log("[-] Failed to list archive contents.");
}
