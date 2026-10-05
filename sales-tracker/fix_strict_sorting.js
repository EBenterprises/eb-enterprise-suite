const fs = require('fs');
const path = require('path');

let serverCode = fs.readFileSync(path.join(__dirname, 'server.js'), 'utf8');

// Replace any weak sorting with a robust string/timestamp descending sort
// This ensures string dates like '2026-10-01 00:13' sort higher than '2026-09-30 12:30'
const oldSortSnippet = `txs.sort((a, b) => (b.timestamp || b.id || 0) - (a.timestamp || a.id || 0));`;
const newSortSnippet = `txs.sort((a, b) => {
        const timeA = a.date ? new Date(a.date.replace(' ', 'T')).getTime() : (a.timestamp || a.id || 0);
        const timeB = b.date ? new Date(b.date.replace(' ', 'T')).getTime() : (b.timestamp || b.id || 0);
        return timeB - timeA;
    });`;

if (serverCode.includes(oldSortSnippet)) {
    serverCode = serverCode.replace(oldSortSnippet, newSortSnippet);
} else {
    // If the old snippet isn't there, inject it right after transactions are read
    serverCode = serverCode.replace(
        `let txs = readJson('transactions.json');`,
        `let txs = readJson('transactions.json');\n    txs.sort((a, b) => {\n        const timeA = a.date ? new Date(a.date.replace(' ', 'T')).getTime() : (a.timestamp || a.id || 0);\n        const timeB = b.date ? new Date(b.date.replace(' ', 'T')).getTime() : (b.timestamp || b.id || 0);\n        return timeB - timeA;\n    });`
    );
}

fs.writeFileSync(path.join(__dirname, 'server.js'), serverCode);
console.log("[+] Successfully updated server.js with strict date-time descending sorting!");
