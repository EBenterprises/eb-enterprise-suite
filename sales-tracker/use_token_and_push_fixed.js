const { execSync } = require('child_process');

console.log("[+] Configuring repository remote with your corrected GitHub token...");

const token = "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";

try {
    const repoUrl = `https://${token}@github.com/EBenterprises/sales-tracker.git`;
    execSync(`git remote set-url origin ${repoUrl}`, { stdio: 'inherit' });
    
    console.log("[+] Pushing 'android_apk_project' and build pipeline to GitHub...");
    execSync('git push origin main', { stdio: 'inherit' });
    
    console.log("\n[+] Success! Repository pushed to GitHub.");
    console.log("[+] Your cloud build workflow / PWABuilder can now generate your signed standalone APK binary package instantly!");
} catch (e) {
    console.log("[-] Push failed. Please verify the token permissions or check remote settings.");
}
