const { execSync } = require('child_process');
const fs = require('fs');

console.log("[+] Committing and synchronizing android_apk_project to GitHub for cloud APK build workflow...");

try {
    execSync('git add android_apk_project/ build_apk.sh', { stdio: 'inherit' });
    execSync('git commit -m "Add native Android WebView wrapper project and build script for standalone APK compilation"', { stdio: 'inherit' });
    console.log("[+] Changes successfully committed to git repository.");
    console.log("[+] To sync with your remote EBenterprises organization repository, run: git push origin main");
} catch (e) {
    console.log("[+] Git status is clean or commit already exists.");
}
