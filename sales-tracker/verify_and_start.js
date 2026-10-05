const fs = require('fs');
const path = require('path');
const file = path.join(__dirname, 'transactions.json');

if (!fs.existsSync(file)) {
    console.log('Creating default transactions.json');
    fs.writeFileSync(file, JSON.stringify([], null, 2));
} else {
    try {
        const data = JSON.parse(fs.readFileSync(file, 'utf8'));
        console.log('Verified transactions.json with ' + data.length + ' records.');
    } catch(e) {
        console.log('Resetting corrupted transactions.json');
        fs.writeFileSync(file, JSON.stringify([], null, 2));
    }
}
