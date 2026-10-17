const fs = require('fs');

console.log("[+] Searching codebase for 'EB Enterprises P2P Master Suite' or interactive map picker implementations...");

const files = fs.readdirSync('.');
let candidateFiles = [];

files.forEach(f => {
    if (f.endsWith('.js') && f !== 'locate_v5_master_suite.js') {
        const content = fs.readFileSync(f, 'utf8');
        if (content.includes('P2P Master Suite') || content.includes('Leaflet') || content.includes('map') || content.includes('51205')) {
            candidateFiles.push({ filename: f, size: content.length });
        }
    }
});

console.log("\n[+] Found matching v5 Master Suite candidates:");
candidateFiles.forEach(c => console.log(`    - ${c.filename} (${c.size} bytes)`));

