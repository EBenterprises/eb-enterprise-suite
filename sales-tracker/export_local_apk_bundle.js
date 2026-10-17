const fs = require('fs');
const { execSync } = require('child_process');

console.log("[+] Network access to GitHub API is restricted in this environment.");
console.log("[+] Bypassing git push restriction: Packaging the native Android WebView project into a standalone local archive (.zip / tar.gz) for direct deployment!");

try {
    execSync('tar -czf eb_sales_tracker_android_wrapper.tar.gz android_apk_project/ build_apk.sh', { stdio: 'inherit' });
    console.log("\n[+] SUCCESS! Standalone APK wrapper archive created: eb_sales_tracker_android_wrapper.tar.gz");
    console.log("[+] You can transfer this archive to your computer, open it in Android Studio, or upload it directly to any cloud APK builder to generate your final signed APK instantly!");
} catch (e) {
    console.log("[-] Failed to create archive.");
}
