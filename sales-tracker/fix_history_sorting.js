const fs = require('fs');
const path = require('path');

const serverPath = path.join(__dirname, 'server.js');
let code = fs.readFileSync(serverPath, 'utf8');

// The user clarifies: "History still showing 1st entry on top and i want most recent not chronological but chronological i know what im saying."
// Meaning: Most recent (newest) transaction should be displayed at the very top of the list (reverse-chronological order: latest timestamp first).
// Let's find any .sort() functions operating on transactions for history / active lists and ensure they sort descending: (b.timestamp || b.id || 0) - (a.timestamp || a.id || 0)

code = code.replace(
    /\.sort\(\s*\(a,\s*b\)\s*=>\s*\(([^)]+)\)\s*\)/g,
    (match, inner) => {
        // If it's sorting by timestamp ascending, flip it to descending
        if (inner.includes('timestamp') || inner.includes('id')) {
            return `.sort((a, b) => (b.timestamp || b.id || 0) - (a.timestamp || a.id || 0))`;
        }
        return match;
    }
);

// Specifically replace any explicit ascending sort patterns on transactions arrays
code = code.replace(
    /transactions\.sort\(\s*\(a,\s*b\)\s*=>\s*\(a\.timestamp\s*\Vert{}\Vert{}\s*0\)\s*-\s*\(b\.timestamp\s*\Vert{}\Vert{}\s*0\)\s*\)/g,
    "transactions.sort((a, b) => (b.timestamp || 0) - (a.timestamp || 0))"
);

code = code.replace(
    /txs\.sort\(\s*\(a,\s*b\)\s*=>\s*\(a\.timestamp\s*\Vert{}\Vert{}\s*0\)\s*-\s*\(b\.timestamp\s*\Vert{}\Vert{}\s*0\)\s*\)/g,
    "txs.sort((a, b) => (b.timestamp || 0) - (a.timestamp || 0))"
);

fs.writeFileSync(serverPath, code);
console.log("[+] History sorting updated to reverse-chronological (newest/most recent first).");
