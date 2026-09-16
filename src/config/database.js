const fs = require('fs');
const path = require('path');

const dbPath = path.resolve(__dirname, '../../database.json');

const readDB = () => {
  if (!fs.existsSync(dbPath)) {
    const initialData = { users: [], settings: [], audit_logs: [] };
    fs.writeFileSync(dbPath, JSON.stringify(initialData, null, 2));
    return initialData;
  }
  try {
    const data = fs.readFileSync(dbPath, 'utf8');
    return JSON.parse(data);
  } catch (err) {
    return { users: [], settings: [], audit_logs: [] };
  }
};

const writeDB = (data) => {
  fs.writeFileSync(dbPath, JSON.stringify(data, null, 2));
};

const db = {
  getUsers: () => readDB().users,
  getSettings: () => readDB().settings,
  getAuditLogs: () => readDB().audit_logs || [],
  save: (data) => writeDB(data)
};

console.log('Connected to zero-dependency JSON database storage (Enterprise Engine).');

module.exports = db;
