const fs = require('fs');
const path = require('path');

const dataDir = path.join(__dirname, '../../data');
const dbFile = path.join(dataDir, 'tap-members.json');

if (!fs.existsSync(dataDir)) {
    fs.mkdirSync(dataDir, { recursive: true });
}

if (!fs.existsSync(dbFile)) {
    fs.writeFileSync(dbFile, JSON.stringify([
        { id: 1, email: 'eastonbodeuxenterprises@gmail.com', role: 'FOUNDER', joined: new Date().toISOString() },
        { id: 2, email: 'pioneer@tap.eco', role: 'AFFILIATE', joined: new Date().toISOString() }
    ], null, 2));
}

module.exports = {
    getMembers: () => JSON.parse(fs.readFileSync(dbFile, 'utf8')),
    addMember: (email) => {
        const members = JSON.parse(fs.readFileSync(dbFile, 'utf8'));
        const newMember = { id: members.length + 1, email, role: 'AFFILIATE', joined: new Date().toISOString() };
        members.push(newMember);
        fs.writeFileSync(dbFile, JSON.stringify(members, null, 2));
        return newMember;
    }
};
