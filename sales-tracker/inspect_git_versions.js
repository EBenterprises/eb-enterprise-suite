const { execSync } = require('child_process');
const fs = require('fs');

console.log("[+] Inspecting Git commit history to locate the cleanest pre-clutter version of server.js...");

try {
    const logs = execSync('git log --all --grep="v5" --oneline -n 10 || git log --oneline -n 10', { encoding: 'utf8' });
    console.log("Recent relevant commits:\n" + logs);
    
    // Find the last commit that touched server.js before all the wrap scripts
    const serverCommits = execSync('git log --oneline -n 10 -- server.js', { encoding: 'utf8' });
    console.log("Commits touching server.js:\n" + serverCommits);
} catch (e) {
    console.log("[!] Git log inspection error:", e.message);
}
