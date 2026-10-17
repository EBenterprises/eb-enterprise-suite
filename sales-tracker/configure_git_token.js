const { execSync } = require('child_process');
const readline = require('readline');

const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});

console.log("[!] GitHub security scan recently revoked your previous personal access token due to an exposed secret in your repository.");
rl.question("[?] Please enter your new GitHub Personal Access Token (PAT): ", (token) => {
    if (!token || token.trim() === '') {
        console.log("[-] No token provided. Exiting.");
        rl.close();
        return;
    }

    try {
        const repoUrl = `https://${token.trim()}@github.com/EBenterprises/sales-tracker.git`;
        execSync(`git remote set-url origin ${repoUrl}`, { stdio: 'inherit' });
        console.log("[+] Remote URL updated successfully with your new token.");
        
        console.log("[+] Pushing repository changes to GitHub...");
        execSync('git push origin main', { stdio: 'inherit' });
        console.log("[+] Successfully pushed changes to GitHub! Your cloud APK build workflow can now trigger.");
    } catch (e) {
        console.log("[-] Failed to push with the provided token. Please verify your token permissions.");
    }
    rl.close();
});
