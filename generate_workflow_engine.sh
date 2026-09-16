#!/bin/bash
set -e

echo "================================================================"
echo " INITIALIZING GLOBAL STANDARD WORKFLOW (GSW) ENGINE"
echo "================================================================"

# Step 1: Create directory structure
mkdir -p global-standard-workflow/public
cd global-standard-workflow

# Step 2: Generate Session Secret & Configuration
SESSION_SECRET=$(node -e "console.log(require('crypto').randomBytes(64).toString('hex'))")

cat << 'EOT' > package.json
{
  "name": "global-standard-workflow",
  "version": "1.0.0",
  "private": true,
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {}
}
EOT

cat << EOT > .env
PORT=3000
SESSION_SECRET=$SESSION_SECRET
DB_FILE=workflows.json
EOT

# Step 3: Server Backend Implementation (Zero-Dependency)
cat << 'EOT' > server.js
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
EOT

# Step 4: Frontend UI Implementation (Executive Spectrum Theme)
cat << 'EOT' > public/index.html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Global Standard Workflow - Executive Dashboard</title>
  <style>
    :root {
      --bg-obsidian: #0b0f19;
      --card-bg: #111827;
      --border-color: #1f2937;
      --accent-teal: #0d9488;
      --accent-gold: #eab308;
      --text-main: #f3f4f6;
      --text-muted: #9ca3af;
      --success-green: #10b981;
    }
    body {
      background-color: var(--bg-obsidian);
      color: var(--text-main);
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      margin: 0;
      padding: 30px;
    }
    header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      border-bottom: 1px solid var(--border-color);
      padding-bottom: 20px;
      margin-bottom: 30px;
    }
    h1 {
      color: var(--accent-gold);
      font-size: 24px;
      margin: 0;
      letter-spacing: 0.5px;
    }
    .badge {
      background: rgba(13, 148, 136, 0.2);
      color: var(--accent-teal);
      border: 1px solid var(--accent-teal);
      padding: 6px 12px;
      border-radius: 20px;
      font-size: 13px;
      font-weight: bold;
    }
    .grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 30px;
    }
    @media(max-width: 900px) {
      .grid { grid-template-columns: 1fr; }
    }
    .card {
      background-color: var(--card-bg);
      border: 1px solid var(--border-color);
      border-radius: 10px;
      padding: 25px;
      box-shadow: 0 10px 25px rgba(0,0,0,0.4);
    }
    h2 {
      font-size: 18px;
      color: var(--accent-teal);
      margin-top: 0;
      border-bottom: 1px solid var(--border-color);
      padding-bottom: 10px;
    }
    .workflow-item {
      background: #1f2937;
      border-left: 4px solid var(--accent-gold);
      padding: 15px;
      border-radius: 6px;
      margin-bottom: 15px;
    }
    .workflow-title {
      font-weight: bold;
      font-size: 16px;
      margin-bottom: 5px;
    }
    .workflow-meta {
      font-size: 12px;
      color: var(--text-muted);
      margin-bottom: 10px;
    }
    button {
      background: var(--accent-teal);
      color: white;
      border: none;
      padding: 8px 16px;
      border-radius: 6px;
      font-weight: bold;
      cursor: pointer;
      transition: background 0.2s;
    }
    button:hover {
      background: #0f766e;
    }
    ul {
      margin: 8px 0 0 0;
      padding-left: 20px;
      font-size: 13px;
      color: var(--text-muted);
    }
    li {
      margin-bottom: 4px;
    }
  </style>
</head>
<body>

<header>
  <h1>GLOBAL STANDARD WORKFLOW (GSW)</h1>
  <div class="badge">Executive Spectrum Active</div>
</header>

<div class="grid">
  <!-- Active Global Standards -->
  <div class="card">
    <h2>Registered Standard Workflows</h2>
    <div id="standardsContainer">Loading standards...</div>
  </div>

  <!-- Live Execution Logs -->
  <div class="card">
    <h2>Active Pipeline Executions</h2>
    <div id="executionsContainer">No active executions logged.</div>
  </div>
</div>

<script>
  async function loadData() {
    try {
      const [stdRes, execRes] = await Promise.all([
        fetch('/api/standards'),
        fetch('/api/executions')
      ]);
      const standards = await stdRes.json();
      const executions = await execRes.json();

      const stdContainer = document.getElementById('standardsContainer');
      stdContainer.innerHTML = standards.map(s => `
        <div class="workflow-item">
          <div class="workflow-title">[${s.code}] ${s.title}</div>
          <div class="workflow-meta">Category: ${s.category} | Version: ${s.version}</div>
          <ul>
            ${s.steps.map(step => `<li>Step ${step.id}: ${step.title}</li>`).join('')}
          </ul>
          <button onclick="executeWorkflow('${s.id}')" style="margin-top: 12px;">Trigger Pipeline Execution</button>
        </div>
      `).join('');

      const execContainer = document.getElementById('executionsContainer');
      if (executions.length === 0) {
        execContainer.innerHTML = '<p style="color: var(--text-muted);">No pipeline runs recorded yet.</p>';
      } else {
        execContainer.innerHTML = executions.map(e => `
          <div class="workflow-item" style="border-left-color: var(--success-green);">
            <div class="workflow-title">${e.code}: ${e.title}</div>
            <div class="workflow-meta">Operator: ${e.operator} | Started: ${new Date(e.timestamp).toLocaleTimeString()}</div>
            <div style="font-size: 13px; color: var(--success-green); font-weight: bold;">Status: ${e.status}</div>
          </div>
        `).join('');
      }
    } catch (err) {
      console.error('Failed to load workflow data:', err);
    }
  }

  async function executeWorkflow(standardId) {
    await fetch('/api/executions', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ standardId, operator: 'System Principal' })
    });
    loadData();
  }

  loadData();
</script>

</body>
</html>
EOT

echo "================================================================"
echo " GSW ENGINE BUILT SUCCESSFULLY!"
echo "================================================================"
echo "To start your global standard workflow engine, run:"
echo "cd global-standard-workflow && npm start"
