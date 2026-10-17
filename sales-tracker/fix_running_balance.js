const fs = require('fs');
const path = require('path');

const serverPath = path.join(__dirname, 'server.js');
let code = fs.readFileSync(serverPath, 'utf8');

// Let's inspect how balance is calculated/rendered in server.js for transactions.
// In many of these suite versions, `t.balance` or the card balance display shows either:
// 1. The individual transaction balance (`amount - cashCollected`)
// 2. OR the cumulative running balance for that customer up to that transaction.
// Let's check how templates calculate running balance per customer vs individual balance.

const idx = code.indexOf("calcBal");
if (idx !== -1) {
    console.log("Found calcBal reference around index:", idx);
    console.log(code.substring(idx - 100, idx + 400));
} else {
    // Let's search for balance calculation in server.js
    const bIdx = code.indexOf("balance");
    if (bIdx !== -1) {
        console.log("Found balance reference around index:", bIdx);
        console.log(code.substring(bIdx - 100, code.indexOf("balance") + 400));
    }
}
