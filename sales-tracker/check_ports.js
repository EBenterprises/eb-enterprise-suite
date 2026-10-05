const fs = require('fs');
const path = require('path');

const files = fs.readdirSync('.');
files.forEach(f => {
    if (f.includes('server') || f.includes('app') || f.includes('v5') || f.includes('v4')) {
        console.log("=== " + f + " ===");
        try {
            const head = fs.readFileSync(f, 'utf8').slice(0, 300);
            console.log(head);
        } catch(e) {}
    }
});
