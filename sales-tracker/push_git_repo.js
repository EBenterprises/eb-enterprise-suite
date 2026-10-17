const { execSync } = require('child_process');

console.log("[+] Configuring Git credential helper and pushing to EBenterprises organization...");

try {
    // Ensure credential store is enabled or use token/SSH if configured, 
    // or set up standard git push command
    execSync('git push origin main', { stdio: 'inherit' });
} catch (e) {
    console.log("[-] Git push encountered authentication error.");
    console.log("[+] Let's check remote URL or configure credentials automatically.");
}
