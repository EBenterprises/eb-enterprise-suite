const { execSync } = require('child_process');
const fs = require('fs');

console.log("[+] Searching git commit history for references to 'customTimestamp', 'tab-history', or time-travel history edits...");

try {
    // Search all commits for customTimestamp or edit_ts
    const commits = execSync('git log --all -S "customTimestamp" --oneline || git log --all -S "edit_ts" --oneline', { encoding: 'utf8' });
    console.log("Commits mentioning time travel / history edits:\n" + commits);

    const lines = commits.trim().split('\n').filter(Boolean);
    if (lines.length > 0) {
        const targetCommit = lines[0].split(' ')[0];
        console.log(`[+] Inspecting/Restoring from commit: ${targetCommit}`);
        
        // Find which file had it in that commit
        const filesInCommit = execSync(`git ls-tree -r --name-only ${targetCommit}`, { encoding: 'utf8' });
        console.log("Files in commit:\n" + filesInCommit);

        // Try checking out server.js or the main js file from that commit
        execSync(`git checkout ${targetCommit} -- server.js || git checkout ${targetCommit}`, { stdio: 'inherit' });
        console.log("[+] Successfully restored files from commit " + targetCommit);
    } else {
        console.log("[!] No specific commit found with 'customTimestamp', searching git reflog...");
        const reflog = execSync('git reflog --oneline -n 20', { encoding: 'utf8' });
        console.log(reflog);
    }
} catch (e) {
    console.log("[!] Error searching git history:", e.message);
}

if (fs.existsSync('server.js')) {
    console.log(`[+] Current server.js size: ${fs.readFileSync('server.js', 'utf8').length} bytes.`);
}
