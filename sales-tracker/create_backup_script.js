const fs = require('fs');
const path = require('path');

const backupScript = `
const fs = require('fs');
const path = require('path');

const backupDir = path.join(__dirname, 'backups');
if (!fs.existsSync(backupDir)) fs.mkdirSync(backupDir);

const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
['transactions.json', 'profiles.json', 'expenses.json'].forEach(file => {
    const filePath = path.join(__dirname, file);
    if (fs.existsSync(filePath)) {
        fs.copyFileSync(filePath, path.join(backupDir, \`\${timestamp}_\${file}\`));
        console.log(\`[+] Backed up \${file} to backups/\${timestamp}_\${file}\`);
    }
});
`;
fs.writeFileSync(path.join(__dirname, 'backup.js'), backupScript);
console.log("[+] backup.js recreated successfully.");
