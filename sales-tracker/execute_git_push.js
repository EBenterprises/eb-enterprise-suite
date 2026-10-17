const { execSync } = require('child_process');

console.log("[+] Checking Git status and pushing native wrapper project...");
try {
    execSync('git push origin main', { stdio: 'inherit' });
    console.log("[+] Successfully pushed changes to GitHub!");
} catch (e) {
    console.log("[-] Authentication required. Please run your git credential configuration or paste your token into the prompt script when ready.");
}
