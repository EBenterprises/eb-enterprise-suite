
const fs = require('fs');
const path = require('path');

const backupDir = path.join(__dirname, 'backups');
if (!fs.existsSync(backupDir)) fs.mkdirSync(backupDir);

const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
const filesToBackup = ['transactions.json', 'profiles.json', 'expenses.json'];

filesToBackup.forEach(file => {
    const filePath = path.join(__dirname, file);
    if (fs.existsSync(filePath)) {
        fs.copyFileSync(filePath, path.join(backupDir, `${timestamp}_${file}`));
        console.log(`[+] Backed up ${file} to backups/${timestamp}_${file}`);
    }
});
