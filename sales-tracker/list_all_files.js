const fs = require('fs');
const path = require('path');

function walk(dir) {
    let results = [];
    const list = fs.readdirSync(dir);
    list.forEach(file => {
        const filePath = path.join(dir, file);
        if (file === '.git' || file === 'node_modules') return;
        const stat = fs.statSync(filePath);
        if (stat && stat.isDirectory()) {
            results = results.concat(walk(filePath));
        } else {
            results.push({ path: filePath, size: stat.size });
        }
    });
    return results;
}

console.log("[+] All files in repository:");
walk('.').forEach(f => {
    console.log(`- ${f.path} (${f.size} bytes)`);
});
