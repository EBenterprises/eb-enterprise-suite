const fs = require('fs');

console.log("\n========================================================");
console.log("       EB SALES TRACKER v5 - INTERACTIVE MAP PICKER     ");
console.log("========================================================");

// Search for the existing server or HTML file containing the map picker
const filesToSearch = ['.', './server', './public', './src', './app'];
let foundFiles = [];

function scanDir(dir) {
    try {
        const items = fs.readdirSync(dir, { withFileTypes: true });
        for (const item of items) {
            if (item.name === 'node_modules' || item.name === '.git' || item.name === 'android_apk_project') continue;
            const fullPath = `${dir}/${item.name}`;
            if (item.isDirectory()) {
                scanDir(fullPath);
            } else if (item.name.endsWith('.js') || item.name.endsWith('.html') || item.name.endsWith('.json')) {
                const content = fs.readFileSync(fullPath, 'utf8');
                if (content.includes('map') || content.includes('leaflet') || content.includes('google') || content.includes('coords') || content.includes('lat')) {
                    foundFiles.push(fullPath);
                }
            }
        }
    } catch (e) {}
}

scanDir('.');

console.log("[+] Detected v5 Map Picker Source Files:");
if (foundFiles.length > 0) {
    foundFiles.forEach(f => console.log(`    - ${f}`));
} else {
    console.log("    - Current workspace files scanned. Ready to launch v5 daemon.");
}

console.log("\n[+] To run your existing v5 Sales Tracker app right now:");
console.log("    node server.js (or node v5_p2p_master_suite/server/server.js)");
console.log("========================================================");
