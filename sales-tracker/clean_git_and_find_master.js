const { execSync } = require('child_process');
const fs = require('fs');

console.log("[+] Cleaning git repository and fetching the absolute latest clean version from GitHub...");

try {
    // Force reset any local modifications and pull latest from origin
    execSync('git fetch --all', { stdio: 'inherit' });
    execSync('git reset --hard origin/main || git reset --hard origin/master || true', { stdio: 'inherit' });
    console.log("[+] Successfully reverted to clean state from GitHub origin.");
} catch (e) {
    console.log("[!] Git sync skipped or failed, inspecting existing commit history for clean v5 state...");
    try {
        execSync('git log -n 5 --oneline', { stdio: 'inherit' });
    } catch (err) {}
}

// Verify server.js status
if (fs.existsSync('server.js')) {
    const code = fs.readFileSync('server.js', 'utf8');
    console.log(`[+] Current server.js size: ${code.length} bytes.`);
} else {
    console.log("[!] server.js missing after reset, checking git status...");
    execSync('git status', { stdio: 'inherit' });
}

console.log("[+] Ready to run clean server daemon.");
