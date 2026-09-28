const fs = require('fs');
const path = require('path');

const dataDir = path.join(__dirname, '../../data');
const dbFile = path.join(dataDir, 'enterprise-registry.json');

if (!fs.existsSync(dataDir)) {
    fs.mkdirSync(dataDir, { recursive: true });
}

if (!fs.existsSync(dbFile)) {
    fs.writeFileSync(dbFile, JSON.stringify({
        organization: "EB Enterprises",
        credentialsFetched: true,
        nodes: [
            { id: 1, name: "www.tap.eco", type: "Affiliate Platform", status: "ACTIVE" },
            { id: 2, name: "BuySideOnline", type: "Web Interface", status: "ACTIVE" },
            { id: 3, name: "CoinScan", type: "Identifier Engine", status: "READY" }
        ],
        updatedAt: new Date().toISOString()
    }, null, 2));
}

module.exports = {
    getRegistry: () => JSON.parse(fs.readFileSync(dbFile, 'utf8')),
    updateRegistry: (data) => {
        fs.writeFileSync(dbFile, JSON.stringify(data, null, 2));
    }
};
