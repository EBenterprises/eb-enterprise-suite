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
