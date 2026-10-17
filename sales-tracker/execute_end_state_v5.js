const fs = require('fs');
const path = require('path');

console.log("[+] Locating end-state backup for server.js...");
const backupDir = path.join(__dirname, 'backups_end_state');

let restored = false;
if (fs.existsSync(backupDir)) {
    const files = fs.readdirSync(backupDir).filter(f => f.includes('server.js'));
    if (files.length > 0) {
        files.sort();
        const latestBackup = path.join(backupDir, files[files.length - 1]);
        console.log(`[+] Restoring from backup: ${files[files.length - 1]}`);
        fs.copyFileSync(latestBackup, path.join(__dirname, 'server.js'));
        restored = true;
    }
}

if (!restored && fs.existsSync('fix_v5_clean_wrapper.js')) {
    console.log("[+] Running fix_v5_clean_wrapper.js directly...");
    try {
        require('child_process').execSync('node fix_v5_clean_wrapper.js', { stdio: 'inherit' });
        restored = true;
    } catch (e) {}
}

if (!restored) {
    console.log("[!] No backup or wrapper script found. Scanning files for any v5 server implementation...");
    const files = fs.readdirSync('.');
    for (const file of files) {
        if (file.endsWith('.js') && file !== 'execute_end_state_v5.js') {
            const content = fs.readFileSync(file, 'utf8');
            if (content.includes('Master Suite') && content.includes('http.createServer')) {
                console.log(`[+] Copying ${file} to server.js`);
                fs.copyFileSync(file, 'server.js');
                restored = true;
                break;
            }
        }
    }
}

console.log("[+] Terminating existing node processes and launching server.js on port 51201/51205...");
try {
    require('child_process').execSync('pkill -f node || true', { stdio: 'inherit' });
} catch (e) {}

require('child_process').execSync('node server.js', { stdio: 'inherit' });
