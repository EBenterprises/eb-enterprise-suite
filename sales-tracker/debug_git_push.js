const { execSync } = require('child_process');

console.log("[+] Checking Git remote and attempting verbose push...");

try {
    // Hide token in logs for safety, but check remote and push
    execSync('git push -v origin main', { stdio: 'inherit' });
} catch (e) {
    console.log("[-] Verbose push encountered an issue. Let's check repository permissions or branch structure.");
    try {
        execSync('git status', { stdio: 'inherit' });
        execSync('git remote -v', { stdio: 'inherit' });
    } catch (err) {}
}
