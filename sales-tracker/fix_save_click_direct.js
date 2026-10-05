const fs = require('fs');
const path = require('path');

const serverPath = path.join(__dirname, 'server.js');
let code = fs.readFileSync(serverPath, 'utf8');

// The issue: parseInt(this.getAttribute('data-id')) fails when transaction IDs are string-based or timestamps! 
// Also, let's inspect the save-edit-btn handler and change parseInt(this.getAttribute('data-id')) to this.getAttribute('data-id') (keeping string/number agnostic)
code = code.replace(
    /document\.querySelectorAll\('\.save-edit-btn'\)\.forEach\(btn\s*=>\s*\{\s*btn\.onclick\s*=\s*async\s*function\(\)\s*\{\s*const\s*id\s*=\s*parseInt\(this\.getAttribute\('data-id'\)\);/g,
    `document.querySelectorAll('.save-edit-btn').forEach(btn => {
        btn.onclick = async function() {
            const id = this.getAttribute('data-id');`
);

// Also make sure table rendering calls bindUI after HTML is injected so that all event listeners attach properly!
// Let's check where loadData or render functions set innerHTML and ensure bindUI or event binding runs after.

fs.writeFileSync(serverPath, code);
console.log("[+] Direct fix applied to save-edit-btn ID parsing.");
