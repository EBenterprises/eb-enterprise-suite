const fs = require('fs');
const path = require('path');

const backupDir = path.join(__dirname, 'backups_end_state');
if (!fs.existsSync(backupDir)) {
    fs.mkdirSync(backupDir, { recursive: true });
}

const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
const filesToBackup = ['server.js', 'transactions.json', 'profiles.json', 'expenses.json'];

filesToBackup.forEach(file => {
    const filePath = path.join(__dirname, file);
    if (fs.existsSync(filePath)) {
        const destName = timestamp + '_' + file;
        const destPath = path.join(backupDir, destName);
        fs.copyFileSync(filePath, destPath);
        console.log('[+] Backed up ' + file + ' to backups_end_state/' + destName);
    } else {
        console.log('[-] Warning: ' + file + ' not found, skipped.');
    }
});

console.log('\n[+] End-state backup successfully secured!');
