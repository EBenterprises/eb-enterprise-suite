const { execSync } = require('child_process');
const fs = require('fs');

console.log("[+] Checking out commit 503f865 (EB Sales Tracker - Multi-Version Release Suite v1-v5)...");
try {
    execSync('git checkout 503f865 -- server.js', { stdio: 'inherit' });
    console.log("[+] Successfully restored server.js from commit 503f865!");
} catch (e) {
    console.log("[!] Checkout failed, attempting to inspect files in commit 503f865...");
    execSync('git ls-tree -r 503f865', { stdio: 'inherit' });
}

if (fs.existsSync('server.js')) {
    const code = fs.readFileSync('server.js', 'utf8');
    console.log(`[+] Restored server.js size: ${code.length} bytes.`);
}

console.log("[+] Ready to run server.js cleanly.");
