const http = require('http');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

if (fs.existsSync('.env')) {
  fs.readFileSync('.env', 'utf8').split('\n').forEach(line => {
    const parts = line.split('=');
    if (parts.length >= 2) {
      process.env[parts[0].trim()] = parts.slice(1).join('=').trim();
    }
  });
}

const PORT = process.env.PORT || 3000;
const DB_FILE = path.resolve(__dirname, process.env.DB_FILE || 'workflows.json');

function readDB() {
  if (!fs.existsSync(DB_FILE)) {
    const initial = {
      standards: [
        {
          id: 'std_01',
          code: 'GSW-OPS-01',
          title: 'Zero-Dependency Infrastructure Deployment',
          category: 'Engineering',
          status: 'Active',
          version: '1.4.0',
          steps: [
            { id: 1, title: 'Environment Scaffolding & Directory Setup', mandatory: true },
            { id: 2, title: 'Cryptographic Secret Generation & ENV Provisioning', mandatory: true },
            { id: 3, title: 'Native HTTP Kernel & Routing Verification', mandatory: true },
            { id: 4, title: 'Executive Spectrum UI Asset Compilation', mandatory: true },
            { id: 5, title: 'Automated Port Scan & Live Daemon Launch', mandatory: true }
          ]
        },
        {
          id: 'std_02',
          code: 'GSW-SEC-02',
          title: 'Cryptographic Authentication & 2FA Protocol',
          category: 'Security',
          status: 'Active',
          version: '2.1.0',
          steps: [
            { id: 1, title: 'PBKDF2 Salted Password Hash Generation', mandatory: true },
            { id: 2, title: 'Ephemeral 6-Digit Code Dispatch via SMTP/Terminal', mandatory: true },
            { id: 3, title: 'Secure HttpOnly Cookie Session Issuance', mandatory: true }
          ]
        }
      ],
      executions: []
    };
    fs.writeFileSync(DB_FILE, JSON.stringify(initial, null, 2));
    return initial;
  }
  try {
    return JSON.parse(fs.readFileSync(DB_FILE, 'utf8'));
  } catch (e) {
    return { standards: [], executions: [] };
  }
}

function writeDB(data) {
  fs.writeFileSync(DB_FILE, JSON.stringify(data, null, 2));
}

const server = http.createServer((req, res) => {
  let body = '';
  req.on('data', chunk => { body += chunk; });
  req.on('end', () => {
    let parsedBody = {};
    try { if (body) parsedBody = JSON.parse(body); } catch (e) {}

    const url = req.url;

    if (req.method === 'GET' && (url === '/' || url === '/index.html')) {
      res.writeHead(200, { 'Content-Type': 'text/html' });
      res.end(fs.readFileSync(path.join(__dirname, 'public/index.html')));
      return;
    }

    if (req.method === 'GET' && url === '/api/standards') {
      const db = readDB();
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify(db.standards));
      return;
    }

    if (req.method === 'POST' && url === '/api/standards') {
      const { code, title, category, steps } = parsedBody;
      if (!code || !title) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Code and title required' }));
        return;
      }
      const db = readDB();
      const newStandard = {
        id: 'std_' + Date.now(),
        code,
        title,
        category: category || 'General',
        status: 'Active',
        version: '1.0.0',
        steps: steps || [{ id: 1, title: 'Initial Phase', mandatory: true }]
      };
      db.standards.push(newStandard);
      writeDB(db);
      res.writeHead(201, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify(newStandard));
      return;
    }

    if (req.method === 'GET' && url === '/api/executions') {
      const db = readDB();
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify(db.executions));
      return;
    }

    if (req.method === 'POST' && url === '/api/executions') {
      const { standardId, operator } = parsedBody;
      const db = readDB();
      const standard = db.standards.find(s => s.id === standardId);
      if (!standard) {
        res.writeHead(404, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Standard workflow not found' }));
        return;
      }

      const execution = {
        id: 'exec_' + Date.now(),
        standardId,
        code: standard.code,
        title: standard.title,
        operator: operator || 'System Administrator',
        timestamp: new Date().toISOString(),
        status: 'In Progress',
        completedSteps: []
      };

      db.executions.unshift(execution);
      writeDB(db);
      res.writeHead(201, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify(execution));
      return;
    }

    res.writeHead(404, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: 'Endpoint not found' }));
  });
});

server.listen(PORT, () => {
  console.log(`Global Standard Workflow Engine active on port ${PORT}`);
});
