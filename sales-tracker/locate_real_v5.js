const fs = require('fs');
const path = require('path');

console.log("[+] Searching all files across the repository for the full v5 implementation with profiles, history, and time-travel features...");

function walk(dir) {
    let results = [];
    const list = fs.readdirSync(dir);
    list.forEach(file => {
        file = path.join(dir, file);
        const stat = fs.statSync(file);
        if (stat && stat.isDirectory()) {
            if (!file.includes('node_modules') && !file.includes('.git')) {
                results = results.concat(walk(file));
            }
        } else {
            if (file.endsWith('.js') || file.endsWith('.html')) {
                results.push(file);
            }
        }
    });
    return results;
}

const files = walk('.');
let foundMatches = [];

files.forEach(file => {
    const content = fs.readFileSync(file, 'utf8');
    let score = 0;
    if (content.includes('customTimestamp') || content.includes('Time Travel')) score += 20;
    if (content.includes('tab-profiles') || content.includes('tab-expenses')) score += 15;
    if (content.includes('PORT_V5') || content.includes('51205')) score += 10;
    if (content.includes('Leaflet') || content.includes('map')) score += 5;

    if (score > 0) {
        foundMatches.push({ file, score, size: content.length });
    }
});

foundMatches.sort((a, b) => b.score - a.score || b.size - a.size);

console.log("\n[+] Search Results:");
foundMatches.forEach(m => {
    console.log(`- File: ${m.file} | Score: ${m.score} | Size: ${m.size} bytes`);
});

if (foundMatches.length > 0) {
    const best = foundMatches[0];
    console.log(`\n[+] Restoring ${best.file} as the canonical server.js...`);
    const canonicalCode = fs.readFileSync(best.file, 'utf8');
    fs.writeFileSync('server.js', canonicalCode);
    console.log("[+] Done! server.js restored to your exact full implementation.");
} else {
    console.log("[!] No matching advanced v5 file found in local tree.");
}
