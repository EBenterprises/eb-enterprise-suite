import express from 'express';
import { WebSocketServer } from 'ws';
import http from 'http';

const app = express();
const server = http.createServer(app);
const wss = new WebSocketServer({ server });

const clients = new Map();
const messageQueues = new Map();
// Simple non-persistent account store for demonstration (maps username -> public identity/verifier)
const accounts = new Map();

app.use(express.json());

// Account verification and registration endpoints
app.post('/api/register', (req, res) => {
  const { username, passwordHash, publicKey } = req.body;
  if (accounts.has(username)) {
    return res.status(400).json({ error: 'Identity already claimed.' });
  }
  accounts.set(username, { passwordHash, publicKey });
  return res.json({ success: true, message: 'Enclave identity initialized.' });
});

app.post('/api/login', (req, res) => {
  const { username, passwordHash } = req.body;
  const account = accounts.get(username);
  if (!account || account.passwordHash !== passwordHash) {
    return res.status(401).json({ error: 'Invalid credentials provided.' });
  }
  return res.json({ success: true, publicKey: account.publicKey });
});

app.post('/api/recover', (req, res) => {
  const { username, newPasswordHash } = req.body;
  if (!accounts.has(username)) {
    return res.status(404).json({ error: 'Identity not found.' });
  }
  const account = accounts.get(username);
  account.passwordHash = newPasswordHash;
  accounts.set(username, account);
  return res.json({ success: true, message: 'Identity keys re-bound.' });
});

wss.on('connection', (ws) => {
  let registeredId = null;

  ws.on('message', (message) => {
    try {
      const data = JSON.parse(message);

      if (data.type === 'REGISTER') {
        registeredId = data.clientId;
        clients.set(registeredId, ws);

        if (messageQueues.has(registeredId)) {
          const queue = messageQueues.get(registeredId);
          while (queue.length > 0) {
            ws.send(JSON.stringify({ type: 'MESSAGE', payload: queue.shift() }));
          }
          messageQueues.delete(registeredId);
        }
      } else if (data.type === 'SEND') {
        const { recipientId, encryptedPayload } = data;
        if (clients.has(recipientId)) {
          clients.get(recipientId).send(JSON.stringify({ type: 'MESSAGE', payload: encryptedPayload }));
        } else {
          if (!messageQueues.has(recipientId)) messageQueues.set(recipientId, []);
          messageQueues.get(recipientId).push(encryptedPayload);
        }
      }
    } catch (err) {
      console.error('[NodeCore Error] Parsing error:', err);
    }
  });

  ws.on('close', () => {
    if (registeredId) clients.delete(registeredId);
  });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`Secure Relay Engine active on port ${PORT}`);
});
