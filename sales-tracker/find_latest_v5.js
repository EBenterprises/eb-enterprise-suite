const fs = require('fs');
const path = require('path');

console.log("[+] Searching all files and backups for the most complete v5 sales-tracker implementation...");

let bestFile = null;
let maxScore = -1;
let bestContent = '';

// Check current directory files
const files = fs.readdirSync('.');
for (const file of files) {
    if (file.endsWith('.js') && file !== 'find_latest_v5.js') {
        const content = fs.readFileSync(file, 'utf8');
        let score = 0;
        if (content.includes('Enterprise P2P Master Suite')) score += 10;
        if (content.includes('Leaflet') || content.includes('map')) score += 5;
        if (content.includes('customTimestamp') || content.includes('time travel')) score += 10;
        if (content.includes('51205') || content.includes('PORT_V5')) score += 5;
        if (content.length > maxScore) {
            maxScore = content.length;
            bestFile = file;
            bestContent = content;
        }
    }
}

// Check backups_end_state if it exists
const backupDir = path.join(__dirname, 'backups_end_state');
if (fs.existsSync(backupDir)) {
    const backupFiles = fs.readdirSync(backupDir);
    for (const file of backupFiles) {
        const fullPath = path.join(backupDir, file);
        if (fs.statSync(fullPath).isFile()) {
            const content = fs.readFileSync(fullPath, 'utf8');
            if (content.length > maxScore && content.includes('Master Suite')) {
                maxScore = content.length;
                bestFile = path.join('backups_end_state', file);
                bestContent = content;
            }
        }
    }
}

if (bestFile) {
    console.log(`[+] Found best matching implementation in: ${bestFile} (${maxScore} bytes)`);
    fs.writeFileSync('server.js', bestContent);
    console.log("[+] Successfully restored this version to server.js!");
} else {
    console.log("[!] No suitable file found.");
}
