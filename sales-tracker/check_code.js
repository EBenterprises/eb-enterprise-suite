const fs = require('fs');
const code = fs.readFileSync('server.js', 'utf8');
const lines = code.split('\n');
lines.forEach((l, i) => {
    if (l.includes('edit_amt') || l.includes('edit_ts') || l.includes('update_tx')) {
        console.log((i+1) + ': ' + l.trim());
    }
});
