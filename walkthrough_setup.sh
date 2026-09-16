#!/bin/bash
set -e

echo "================================================================"
echo " STEP 1: INITIALIZING THE ZERO-DEPENDENCY PROJECT STRUCTURE"
echo "================================================================"
echo "Creating zero-auth-core directories and workspace files..."

mkdir -p zero-auth-core/public
cd zero-auth-core

# Generate a cryptographically secure 512-bit random session secret natively via Node.js
SESSION_SECRET=$(node -e "console.log(require('crypto').randomBytes(64).toString('hex'))")

echo "Generated 512-bit cryptographic session secret."

echo "================================================================"
echo " STEP 2: PROMPTING FOR PRODUCTION DEPLOYMENT CREDENTIALS"
echo "================================================================"

read -p "Enter server port [default 3000]: " INPUT_PORT
PORT=${INPUT_PORT:-3000}

read -p "Enter SMTP Host (e.g., smtp.gmail.com): " INPUT_HOST
read -p "Enter SMTP Port (e.g., 587): " INPUT_PORT_SMTP
read -p "Enter Sender Email Address (SMTP_USER): " INPUT_USER
read -s -p "Enter Email App Password / SMTP_PASS: " INPUT_PASS
echo
read -p "Enter From Display Email (SMTP_FROM): " INPUT_FROM

# Use fallback defaults if inputs are empty
SMTP_HOST=${INPUT_HOST:-smtp.gmail.com}
SMTP_PORT=${INPUT_PORT_SMTP:-587}
SMTP_FROM=${INPUT_FROM:-$INPUT_USER}

echo "Writing environment configuration to .env..."
cat << EOT > .env
PORT=$PORT
SESSION_SECRET=$SESSION_SECRET
DB_FILE=database.json
SMTP_HOST=$SMTP_HOST
SMTP_PORT=$SMTP_PORT
SMTP_USER=$INPUT_USER
SMTP_PASS=$INPUT_PASS
SMTP_FROM=$SMTP_FROM
EOT

echo "================================================================"
echo " STEP 3: CREATING package.json (ZERO EXTERNAL RUNTIME DEPENDENCIES)"
echo "================================================================"
cat << 'EOT' > package.json
{
  "name": "zero-auth-core",
  "version": "1.0.0",
  "private": true,
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {}
}
EOT

echo "================================================================"
echo " STEP 4: IMPLEMENTING PERSISTENCE AND CRYPTO UTILITIES"
echo "================================================================"
cat << 'EOT' > server.js
const http = require('http');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const tls = require('tls');
const net = require('net');

// Load environment variables manually without external dotenv module
if (fs.existsSync('.env')) {
  fs.readFileSync('.env', 'utf8').split('\n').forEach(line => {
    const parts = line.split('=');
    if (parts.length >= 2) {
      process.env[parts[0].trim()] = parts.slice(1).join('=').trim();
    }
  });
}

const PORT = process.env.PORT || 3000;
const DB_FILE = path.resolve(__dirname, process.env.DB_FILE || 'database.json');

// File-system based JSON database implementation
function readDB() {
  if (!fs.existsSync(DB_FILE)) {
    const initial = { users: [], sessions: {} };
    fs.writeFileSync(DB_FILE, JSON.stringify(initial, null, 2));
    return initial;
  }
  try {
    return JSON.parse(fs.readFileSync(DB_FILE, 'utf8'));
  } catch (e) {
    return { users: [], sessions: {} };
  }
}

function writeDB(data) {
  fs.writeFileSync(DB_FILE, JSON.stringify(data, null, 2));
}

// Secure PBKDF2 Password Hashing
function hashPassword(password, salt = crypto.randomBytes(16).toString('hex')) {
  const hash = crypto.pbkdf2Sync(password, salt, 10000, 64, 'sha512').toString('hex');
  return `${salt}:${hash}`;
}

function verifyPassword(password, stored) {
  const [salt, originalHash] = stored.split(':');
  const hash = crypto.pbkdf2Sync(password, salt, 10000, 64, 'sha512').toString('hex');
  return hash === originalHash;
}

// Native Zero-Dependency SMTP Client over raw sockets with TLS / STARTTLS support
function sendRawEmail(to, subject, htmlBody, callback) {
  const host = process.env.SMTP_HOST;
  const port = parseInt(process.env.SMTP_PORT, 10);
  const user = process.env.SMTP_USER;
  const pass = process.env.SMTP_PASS;
  const from = process.env.SMTP_FROM || user;

  if (!user || !pass) {
    console.log('[Mock Email Dispatch]: SMTP credentials not provided. Verification code logged for development:', htmlBody);
    if (callback) callback(null);
    return;
  }

  const plainSocket = net.createConnection({ host, port }, () => {});
  let buffer = '';
  let stage = 0;
  let tlsSocket = null;

  plainSocket.on('data', (chunk) => {
    buffer += chunk.toString();
    const lines = buffer.split('\r\n');
    buffer = lines.pop();

    for (const line of lines) {
      const code = parseInt(line.substring(0, 3), 10);

      if (stage === 0 && code === 220) {
        plainSocket.write(`EHLO localhost\r\n`);
        stage = 1;
      } else if (stage === 1 && line.startsWith('250')) {
        if (line.includes('STARTTLS')) {
          plainSocket.write(`STARTTLS\r\n`);
          stage = 2;
        } else {
          plainSocket.write(`AUTH LOGIN\r\n`);
          stage = 4;
        }
      } else if (stage === 2 && code === 220) {
        tlsSocket = tls.connect({ socket: plainSocket, host, rejectUnauthorized: false }, () => {
          tlsSocket.write(`EHLO localhost\r\n`);
          stage = 3;
        });
        tlsSocket.on('data', handleTlsData);
      }
    }
  });

  function handleTlsData(chunk) {
    const dataStr = chunk.toString();
    if (dataStr.includes('334 VXNlcm5hbWU6')) {
      tlsSocket.write(Buffer.from(user).toString('base64') + '\r\n');
    } else if (dataStr.includes('334 UGFzc3dvcmQ6')) {
      tlsSocket.write(Buffer.from(pass).toString('base64') + '\r\n');
    } else if (dataStr.startsWith('235')) {
      sendMailPayload(tlsSocket);
    } else if (dataStr.startsWith('250 2.0.0 OK') || dataStr.startsWith('250 Accepted')) {
      tlsSocket.write(`QUIT\r\n`);
      if (callback) callback(null);
    }
  }

  function sendMailPayload(sock) {
    sock.write(`MAIL FROM:<${from}>\r\n`);
    sock.write(`RCPT TO:<${to}>\r\n`);
    sock.write(`DATA\r\n`);
    const payload = `From: "Secure Enterprise Portal" <${from}>\r\nTo: <${to}>\r\nSubject: ${subject}\r\nMIME-Version: 1.0\r\nContent-Type: text/html; charset=UTF-8\r\n\r\n${htmlBody}\r\n.\r\n`;
    sock.write(payload);
  }

  plainSocket.on('error', (err) => {
    console.error('SMTP Connection Error:', err);
    if (callback) callback(err);
  });
}

console.log("Core utilities loaded successfully.");
EOT

echo "================================================================"
echo " STEP 5: CREATING HTTP SERVER AND AUTHENTICATION ROUTING"
echo "================================================================"
cat << 'EOT' >> server.js

// HTTP Server Routing & Controllers
const server = http.createServer((req, res) => {
  let body = '';
  req.on('data', chunk => { body += chunk; });
  req.on('end', () => {
    let parsedBody = {};
    try { if (body) parsedBody = JSON.parse(body); } catch (e) {}

    // Parse Cookies helper
    const cookies = {};
    const cookieHeader = req.headers['cookie'];
    if (cookieHeader) {
      cookieHeader.split(';').forEach(cookie => {
        const parts = cookie.split('=');
        cookies[parts[0].trim()] = parts[1] ? parts[1].trim() : '';
      });
    }

    // Static Asset Handlers
    if (req.method === 'GET' && (req.url === '/' || req.url === '/index.html')) {
      res.writeHead(200, { 'Content-Type': 'text/html' });
      res.end(fs.readFileSync(path.join(__dirname, 'public/index.html')));
      return;
    }
    if (req.method === 'GET' && req.url === '/dashboard.html') {
      const sessionToken = cookies['session'];
      const db = readDB();
      if (!sessionToken || !db.sessions[sessionToken] || db.sessions[sessionToken].expires < Date.now()) {
        res.writeHead(302, { 'Location': '/' });
        res.end();
        return;
      }
      res.writeHead(200, { 'Content-Type': 'text/html' });
      res.end(fs.readFileSync(path.join(__dirname, 'public/dashboard.html')));
      return;
    }

    // API Route: Register Account
    if (req.method === 'POST' && req.url === '/api/auth/register') {
      const { email, password } = parsedBody;
      if (!email || !password) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Email and password required' }));
        return;
      }
      const db = readDB();
      if (db.users.find(u => u.email === email)) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'User already exists' }));
        return;
      }
      db.users.push({ id: Date.now(), email, password: hashPassword(password), twoFaCode: null, twoFaExpires: null });
      writeDB(db);
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ message: 'User registered successfully' }));
      return;
    }

    // API Route: Login Step 1 (Verify Password & Trigger 2FA)
    if (req.method === 'POST' && req.url === '/api/auth/login') {
      const { email, password } = parsedBody;
      const db = readDB();
      const user = db.users.find(u => u.email === email);

      if (!user || !verifyPassword(password, user.password)) {
        res.writeHead(401, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Invalid email or password' }));
        return;
      }

      const code = crypto.randomInt(100000, 999999).toString();
      user.twoFaCode = code;
      user.twoFaExpires = Date.now() + 5 * 60 * 1000; // 5 minutes validity
      writeDB(db);

      const htmlBody = `<div style="font-family:sans-serif;padding:25px;background:#0b0f19;color:#f3f4f6;border-radius:8px;"><h2 style="color:#eab308;">Security Verification</h2><p>Your secure authentication code is:</p><div style="background:#111827;padding:15px;font-size:28px;font-weight:bold;letter-spacing:6px;text-align:center;color:#0d9488;border-radius:6px;margin:20px 0;">${code}</div><p style="font-size:12px;color:#9ca3af;">This code expires in 5 minutes.</p></div>`;

      sendRawEmail(email, 'Your 2FA Login Code', htmlBody, (err) => {
        if (err) console.error('Email dispatch error:', err);
      });

      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ message: 'Credentials validated. 2FA code dispatched to email.', requires2FA: true }));
      return;
    }

    // API Route: Login Step 2 (Verify 2FA Code & Issue Session Cookie)
    if (req.method === 'POST' && req.url === '/api/auth/verify-2fa') {
      const { email, code } = parsedBody;
      const db = readDB();
      const user = db.users.find(u => u.email === email);

      if (!user || !user.twoFaCode || Date.now() > user.twoFaExpires || user.twoFaCode !== code) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Invalid or expired 2FA code' }));
        return;
      }

      user.twoFaCode = null;
      user.twoFaExpires = null;
      
      const sessionToken = crypto.randomBytes(32).toString('hex');
      db.sessions[sessionToken] = { userId: user.id, email: user.email, expires: Date.now() + 2 * 3600 * 1000 };
      writeDB(db);

      res.writeHead(200, {
        'Set-Cookie': `session=${sessionToken}; HttpOnly; Path=/; Max-Age=7200; SameSite=Strict`,
        'Content-Type': 'application/json'
      });
      res.end(JSON.stringify({ message: 'Authentication successful', token: sessionToken }));
      return;
    }

    // API Route: Logout
    if (req.method === 'POST' && req.url === '/api/auth/logout') {
      const sessionToken = cookies['session'];
      if (sessionToken) {
        const db = readDB();
        delete db.sessions[sessionToken];
        writeDB(db);
      }
      res.writeHead(200, {
        'Set-Cookie': 'session=; HttpOnly; Path=/; Max-Age=0',
        'Content-Type': 'application/json'
      });
      res.end(JSON.stringify({ message: 'Logged out successfully' }));
      return;
    }

    res.writeHead(404, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: 'Endpoint not found' }));
  });
});

server.listen(PORT, () => {
  console.log(`================================================================`);
  console.log(` Live Production Server running on port ${PORT}`);
  console.log(`================================================================`);
});
EOT

echo "================================================================"
echo " STEP 6: BUILDING THE FRONTEND INTERFACE (index.html)"
echo "================================================================"
cat << 'EOT' > public/index.html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Secure Enterprise Gateway - 2FA Login</title>
  <style>
    :root {
      --bg-color: #0b0f19;
      --card-bg: #111827;
      --border-color: #1f2937;
      --accent-teal: #0d9488;
      --accent-gold: #eab308;
      --text-main: #f3f4f6;
      --text-muted: #9ca3af;
    }
    body {
      background-color: var(--bg-color);
      color: var(--text-main);
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      display: flex;
      justify-content: center;
      align-items: center;
      height: 100vh;
      margin: 0;
    }
    .card {
      background-color: var(--card-bg);
      border: 1px solid var(--border-color);
      padding: 30px;
      border-radius: 12px;
      width: 100%;
      max-width: 400px;
      box-shadow: 0 10px 25px rgba(0,0,0,0.5);
    }
    h2 {
      margin-top: 0;
      color: var(--accent-gold);
      font-size: 22px;
      text-align: center;
    }
    .form-group {
      margin-bottom: 20px;
    }
    label {
      display: block;
      margin-bottom: 8px;
      font-size: 14px;
      color: var(--text-muted);
    }
    input {
      width: 100%;
      padding: 12px;
      background: #1f2937;
      border: 1px solid #374151;
      border-radius: 6px;
      color: white;
      font-size: 16px;
      box-sizing: border-box;
    }
    input:focus {
      outline: none;
      border-color: var(--accent-teal);
    }
    button {
      width: 100%;
      padding: 12px;
      background: var(--accent-teal);
      color: white;
      border: none;
      border-radius: 6px;
      font-size: 16px;
      font-weight: bold;
      cursor: pointer;
      transition: background 0.2s;
    }
    button:hover {
      background: #0f766e;
    }
    .hidden {
      display: none !important;
    }
    .msg {
      margin-top: 15px;
      text-align: center;
      font-size: 14px;
    }
    .error { color: #ef4444; }
    .success { color: #10b981; }
  </style>
</head>
<body>

<div class="card">
  <form id="loginForm">
    <h2>Secure Gateway Login</h2>
    <div class="form-group">
      <label>Email Address</label>
      <input type="email" id="email" required placeholder="name@domain.com">
    </div>
    <div class="form-group">
      <label>Password</label>
      <input type="password" id="password" required placeholder="••••••••">
    </div>
    <button type="submit">Continue to 2FA</button>
  </form>

  <form id="verifyForm" class="hidden">
    <h2>Two-Factor Authentication</h2>
    <p style="font-size: 13px; color: var(--text-muted); text-align: center;">Enter the 6-digit code sent to your email.</p>
    <div class="form-group">
      <label>Verification Code</label>
      <input type="text" id="code" maxlength="6" required placeholder="123456" style="text-align: center; letter-spacing: 6px; font-size: 20px;">
    </div>
    <button type="submit">Verify & Login</button>
  </form>

  <div id="message" class="msg"></div>
</div>

<script>
  let userEmail = '';

  const loginForm = document.getElementById('loginForm');
  const verifyForm = document.getElementById('verifyForm');
  const messageDiv = document.getElementById('message');

  loginForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    userEmail = document.getElementById('email').value;
    const password = document.getElementById('password').value;
    messageDiv.textContent = 'Authenticating credentials...';
    messageDiv.className = 'msg';

    try {
      const res = await fetch('/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: userEmail, password })
      });
      const data = await res.json();

      if (!res.ok) throw new Error(data.error || 'Login failed');

      messageDiv.textContent = data.message;
      messageDiv.className = 'msg success';
      loginForm.classList.add('hidden');
      verifyForm.classList.remove('hidden');
    } catch (err) {
      messageDiv.textContent = err.message;
      messageDiv.className = 'msg error';
    }
  });

  verifyForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    const code = document.getElementById('code').value;
    messageDiv.textContent = 'Verifying security code...';
    messageDiv.className = 'msg';

    try {
      const res = await fetch('/api/auth/verify-2fa', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: userEmail, code })
      });
      const data = await res.json();

      if (!res.ok) throw new Error(data.error || 'Verification failed');

      messageDiv.textContent = 'Access granted! Redirecting...';
      messageDiv.className = 'msg success';
      setTimeout(() => {
        window.location.href = '/dashboard.html';
      }, 1000);
    } catch (err) {
      messageDiv.textContent = err.message;
      messageDiv.className = 'msg error';
    }
  });
</script>

</body>
</html>
EOT

echo "================================================================"
echo " STEP 7: BUILDING THE PROTECTED DASHBOARD (dashboard.html)"
echo "================================================================"
cat << 'EOT' > public/dashboard.html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Dashboard - Secure Terminal</title>
  <style>
    body { background: #0b0f19; color: #f3f4f6; font-family: sans-serif; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; }
    .box { background: #111827; border: 1px solid #1f2937; padding: 40px; border-radius: 12px; text-align: center; box-shadow: 0 10px 25px rgba(0,0,0,0.5); }
    h1 { color: #38bdf8; }
    button { padding: 12px 24px; background: #ef4444; color: white; border: none; border-radius: 6px; cursor: pointer; font-weight: bold; margin-top: 20px; font-size: 16px; }
    button:hover { background: #dc2626; }
  </style>
</head>
<body>
<div class="box">
  <h1>Executive Terminal Access Granted</h1>
  <p>You have successfully authenticated via 2FA email verification.</p>
  <button id="logoutBtn">Logout</button>
</div>
<script>
  document.getElementById('logoutBtn').addEventListener('click', async () => {
    await fetch('/api/auth/logout', { method: 'POST' });
    window.location.href = '/';
  });
</script>
</body>
</html>
EOT

echo "================================================================"
echo " WALKTHROUGH COMPLETE: ZERO-DEPENDENCY APP CREATED SUCCESSFULLY"
echo "================================================================"
echo "To register a test account, run:"
echo "curl -X POST http://localhost:$PORT/api/auth/register -H 'Content-Type: application/json' -d '{\"email\":\"test@example.com\",\"password\":\"mypassword123\"}'"
echo ""
echo "To start your server, run:"
echo "cd zero-auth-core && npm start"
