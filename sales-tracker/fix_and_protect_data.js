const fs = require('fs');
const path = require('path');

const DATA_FILE = path.join(__dirname, 'transactions.json');
const PROFILES_FILE = path.join(__dirname, 'profiles.json');
const EXPENSES_FILE = path.join(__dirname, 'expenses.json');

console.log("[+] Checking existing data files...");

// Create dummy defaults ONLY if files don't exist at all or are empty/invalid
if (!fs.existsSync(DATA_FILE) || fs.readFileSync(DATA_FILE, 'utf8').trim() === '') {
    fs.writeFileSync(DATA_FILE, JSON.stringify([
        { id: 1, timestamp: Date.now(), date: '2026-09-30 05:11', customer: 'Alice', landmark: 'Downtown', gps: '49.8880, -119.4960', item: '28g Preset', amount: 250, cashCollected: 250, balance: 0, status: 'Paid' }
    ], null, 2));
    console.log("[+] Initialized transactions.json");
} else {
    console.log("[+] transactions.json exists and is intact.");
}

if (!fs.existsSync(PROFILES_FILE) || fs.readFileSync(PROFILES_FILE, 'utf8').trim() === '') {
    fs.writeFileSync(PROFILES_FILE, JSON.stringify({
        'Alice': { phone: '555-0192', notes: 'VIP Client - Cash on delivery preferred' }
    }, null, 2));
    console.log("[+] Initialized profiles.json");
} else {
    console.log("[+] profiles.json exists and is intact.");
}

if (!fs.existsSync(EXPENSES_FILE) || fs.readFileSync(EXPENSES_FILE, 'utf8').trim() === '') {
    fs.writeFileSync(EXPENSES_FILE, JSON.stringify([
        { id: 1, timestamp: Date.now(), date: '2026-09-30', category: 'Packaging', amount: 15.00, notes: 'Ziploc bags & scales' }
    ], null, 2));
    console.log("[+] Initialized expenses.json");
} else {
    console.log("[+] expenses.json exists and is intact.");
}
