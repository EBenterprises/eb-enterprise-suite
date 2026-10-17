const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const cors = require('cors');
const fs = require('fs');
const path = require('path');

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: "*", methods: ["GET", "POST"] }
});

app.use(cors());
app.use(express.json());

const DB_FILE = path.join(__dirname, 'database.json');

if (!fs.existsSync(DB_FILE)) {
  fs.writeFileSync(DB_FILE, JSON.stringify({ users: [], messages: [] }, null, 2));
}

const readDB = () => JSON.parse(fs.readFileSync(DB_FILE, 'utf8'));
const writeDB = (data) => fs.writeFileSync(DB_FILE, JSON.stringify(data, null, 2));

const generateToken = (id) => {
  return jwt.sign({ id }, 'supersecretsecureplugkey123', { expiresIn: '30d' });
};

app.post('/api/auth/register', async (req, res) => {
  try {
    const { username, pin, role } = req.body;
    if (!username || !pin) return res.status(400).json({ message: 'Alias and PIN required.' });

    const db = readDB();
    const userExists = db.users.find(u => u.username === username);
    if (userExists) return res.status(400).json({ message: 'Alias already taken.' });

    const salt = await bcrypt.genSalt(10);
    const hashedPin = await bcrypt.hash(pin, salt);

    const newUser = {
      _id: 'user_' + Date.now() + Math.random().toString(36).substring(2, 7),
      username,
      pin: hashedPin,
      role: role || 'client',
      createdAt: new Date().toISOString()
    };

    db.users.push(newUser);
    writeDB(db);

    res.status(201).json({
      _id: newUser._id,
      username: newUser.username,
      role: newUser.role,
      token: generateToken(newUser._id)
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

app.post('/api/auth/login', async (req, res) => {
  try {
    const { username, pin } = req.body;
    const db = readDB();
    const user = db.users.find(u => u.username === username);

    if (user && (await bcrypt.compare(pin, user.pin))) {
      res.json({
        _id: user._id,
        username: user.username,
        role: user.role,
        token: generateToken(user._id)
      });
    } else {
      res.status(401).json({ message: 'Invalid alias or secure PIN.' });
    }
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

app.get('/api/auth/plugs', async (req, res) => {
  try {
    const db = readDB();
    const plugs = db.users
      .filter(u => u.role === 'plug' || u.role === 'admin')
      .map(({ pin, ...u }) => u);
    res.json(plugs);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

app.get('/api/messages/:userId/:contactId', async (req, res) => {
  try {
    const { userId, contactId } = req.params;
    const db = readDB();
    const messages = db.messages.filter(m => 
      (m.sender === userId && m.recipient === contactId) ||
      (m.sender === contactId && m.recipient === userId)
    ).sort((a, b) => new Date(a.createdAt) - new Date(b.createdAt));
    res.json(messages);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

io.on('connection', (socket) => {
  socket.on('join_room', (userId) => {
    socket.join(userId);
  });

  socket.on('send_message', async (data) => {
    try {
      const { sender, recipient, text, burnAfterRead } = data;
      const db = readDB();
      const message = {
        _id: 'msg_' + Date.now() + Math.random().toString(36).substring(2, 7),
        sender,
        recipient,
        text,
        burnAfterRead: burnAfterRead ?? true,
        createdAt: new Date().toISOString()
      };
      
      db.messages.push(message);
      writeDB(db);
      
      io.to(recipient).emit('receive_message', message);
      io.to(sender).emit('receive_message', message);
    } catch (error) {
      console.error('Socket message error:', error);
    }
  });
});

app.get('*', (req, res) => {
  res.send(`<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Secure Drop - Monolith Messenger</title>
  <script src="https://cdn.tailwindcss.com"></script>
  <script src="/socket.io/socket.io.js"></script>
  <script>
    tailwind.config = {
      theme: {
        extend: {
          colors: {
            darkBg: '#0b0f19',
            cardBg: '#111827',
            neonGreen: '#10b981',
            neonHover: '#059669',
            neonRed: '#ef4444'
          }
        }
      }
    }
  </script>
</head>
<body class="bg-darkBg text-gray-100 font-mono h-screen flex flex-col overflow-hidden">
  <div id="app" class="h-full flex flex-1"></div>
  <script>
    const socket = io();
    let currentUser = JSON.parse(localStorage.getItem('plug_user')) || null;
    let selectedContact = null;
    let messages = [];
    let plugs = [];

    function render() {
      const app = document.getElementById('app');
      if (!currentUser) {
        app.innerHTML = \`
          <div class="flex h-full w-full items-center justify-center p-4">
            <div class="w-full max-w-md bg-cardBg border border-gray-800 rounded-xl p-8 shadow-2xl">
              <h1 class="text-2xl font-bold text-neonGreen text-center mb-1 tracking-wider">SECURE DROP</h1>
              <p class="text-xs text-gray-400 text-center mb-6 uppercase tracking-widest">Monolithic Encrypted Tunnel</p>
              <div id="error-box" class="hidden bg-neonRed/20 border border-neonRed text-neonRed text-sm p-3 rounded mb-4 text-center"></div>
              <form id="auth-form" class="space-y-4">
                <div>
                  <label class="block text-xs text-gray-400 mb-1 uppercase">Alias / Username</label>
                  <input type="text" id="username" required class="w-full bg-darkBg border border-gray-700 rounded p-3 text-white focus:outline-none focus:border-neonGreen" placeholder="Enter alias...">
                </div>
                <div>
                  <label class="block text-xs text-gray-400 mb-1 uppercase">Secret PIN</label>
                  <input type="password" id="pin" required class="w-full bg-darkBg border border-gray-700 rounded p-3 text-white focus:outline-none focus:border-neonGreen" placeholder="••••">
                </div>
                <div id="role-container" class="hidden">
                  <label class="block text-xs text-gray-400 mb-1 uppercase">Account Role</label>
                  <select id="role" class="w-full bg-gray-900 border border-gray-700 rounded p-3 text-white focus:outline-none focus:border-neonGreen">
                    <option value="client">Client (Customer)</option>
                    <option value="plug">The Plug (Vendor)</option>
                  </select>
                </div>
                <button type="submit" id="auth-btn" class="w-full bg-neonGreen text-darkBg font-bold py-3 rounded hover:bg-neonHover transition uppercase tracking-wider">Decrypt Session</button>
              </form>
              <div class="mt-6 text-center">
                <button id="toggle-mode" class="text-xs text-gray-400 hover:text-neonGreen underline uppercase tracking-wider">Need an alias? Register account</button>
              </div>
            </div>
          </div>
        \`;

        let isRegistering = false;
        document.getElementById('toggle-mode').onclick = () => {
          isRegistering = !isRegistering;
          document.getElementById('role-container').classList.toggle('hidden', !isRegistering);
          document.getElementById('toggle-mode').innerText = isRegistering ? 'Already have credentials? Access vault' : 'Need an alias? Register account';
          document.getElementById('auth-btn').innerText = isRegistering ? 'Establish Identity' : 'Decrypt Session';
        };

        document.getElementById('auth-form').onsubmit = async (e) => {
          e.preventDefault();
          const username = document.getElementById('username').value;
          const pin = document.getElementById('pin').value;
          const role = document.getElementById('role')?.value || 'client';
          const endpoint = isRegistering ? '/api/auth/register' : '/api/auth/login';

          const res = await fetch(endpoint, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ username, pin, role })
          });
          const data = await res.json();
          if (!res.ok) {
            const errBox = document.getElementById('error-box');
            errBox.innerText = data.message;
            errBox.classList.remove('hidden');
            return;
          }
          localStorage.setItem('plug_user', JSON.stringify(data));
          currentUser = data;
          initSocket();
          fetchPlugs();
          render();
        };
      } else {
        app.innerHTML = \`
          <div class="w-1/3 border-r border-gray-800 bg-cardBg flex flex-col">
            <div class="p-4 border-b border-gray-800 flex justify-between items-center">
              <div>
                <div class="font-bold text-neonGreen">\${currentUser.username}</div>
                <div class="text-xs text-gray-500 uppercase">Role: \${currentUser.role}</div>
              </div>
              <button id="logout-btn" class="text-xs bg-gray-800 text-gray-300 px-3 py-1.5 rounded hover:bg-neonRed hover:text-white transition">Wipe Session</button>
            </div>
            <div class="p-3 bg-gray-900/40 text-xs font-bold text-gray-400 uppercase tracking-wider">Available Plugs</div>
            <div id="plugs-list" class="flex-1 overflow-y-auto divide-y divide-gray-800/50"></div>
          </div>
          <div class="flex-2 flex flex-col bg-darkBg w-full" id="chat-panel">
            <div class="flex-1 flex flex-col items-center justify-center text-gray-500">
              <p class="text-lg">Select a plug from the sidebar to establish a secure link.</p>
            </div>
          </div>
        \`;

        document.getElementById('logout-btn').onclick = () => {
          localStorage.removeItem('plug_user');
          currentUser = null;
          selectedContact = null;
          render();
        };

        renderPlugs();
        if (selectedContact) renderChat();
      }
    }

    function renderPlugs() {
      const list = document.getElementById('plugs-list');
      if (!list) return;
      if (plugs.length === 0) {
        list.innerHTML = '<div class="p-4 text-center text-gray-500 text-sm">No operational plugs online.</div>';
        return;
      }
      list.innerHTML = plugs.map(p => \`
        <div onclick="selectPlug('\${p._id}')" class="p-4 cursor-pointer transition flex items-center justify-between \${selectedContact?._id === p._id ? 'bg-gray-800/80 border-l-4 border-neonGreen' : 'hover:bg-gray-800/40'}">
          <div>
            <div class="font-semibold text-white">\${p.username}</div>
            <div class="text-xs text-neonGreen">● Online & Encrypted</div>
          </div>
        </div>
      \`).join('');
    }

    async function selectPlug(id) {
      selectedContact = plugs.find(p => p._id === id);
      renderPlugs();
      const res = await fetch(\`/api/messages/\${currentUser._id}/\${selectedContact._id}\`);
      messages = await res.json();
      renderChat();
    }

    function renderChat() {
      const panel = document.getElementById('chat-panel');
      if (!panel || !selectedContact) return;
      panel.innerHTML = \`
        <div class="p-4 border-b border-gray-800 bg-cardBg flex justify-between items-center">
          <div>
            <h2 class="font-bold text-white">Secure Channel: \${selectedContact.username}</h2>
            <span class="text-xs text-neonGreen">End-to-End Monolithic Tunnel</span>
          </div>
        </div>
        <div id="msg-container" class="flex-1 overflow-y-auto p-4 space-y-3">
          \${messages.map(m => \`
            <div class="flex \${m.sender === currentUser._id ? 'justify-end' : 'justify-start'}">
              <div class="max-w-md rounded-lg p-3 text-sm \${m.sender === currentUser._id ? 'bg-neonGreen text-darkBg font-medium' : 'bg-gray-800 text-gray-100'}">
                <p>\${m.text}</p>
                <span class="block text-[10px] mt-1 text-right \${m.sender === currentUser._id ? 'text-gray-900' : 'text-gray-400'}">
                  \${new Date(m.createdAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                </span>
              </div>
            </div>
          \`).join('')}
        </div>
        <form id="msg-form" class="p-4 border-t border-gray-800 bg-cardBg flex gap-2">
          <input type="text" id="msg-input" autocomplete="off" placeholder="Type secure drop payload..." class="flex-1 bg-darkBg border border-gray-700 rounded p-3 text-white focus:outline-none focus:border-neonGreen">
          <button type="submit" class="bg-neonGreen text-darkBg font-bold px-6 rounded hover:bg-neonHover transition uppercase tracking-wider">Transmit</button>
        </form>
      \`;

      const container = document.getElementById('msg-container');
      container.scrollTop = container.scrollHeight;

      document.getElementById('msg-form').onsubmit = (e) => {
        e.preventDefault();
        const input = document.getElementById('msg-input');
        const text = input.value.trim();
        if (!text) return;

        socket.emit('send_message', {
          sender: currentUser._id,
          recipient: selectedContact._id,
          text
        });
        input.value = '';
      };
    }

    async function fetchPlugs() {
      const res = await fetch('/api/auth/plugs');
      plugs = await res.json();
      renderPlugs();
    }

    function initSocket() {
      if (!currentUser) return;
      socket.emit('join_room', currentUser._id);
      socket.on('receive_message', (msg) => {
        if (selectedContact && (msg.sender === selectedContact._id || msg.recipient === selectedContact._id)) {
          messages.push(msg);
          renderChat();
        }
      });
    }

    if (currentUser) {
      initSocket();
      fetchPlugs();
    }
    render();
  </script>
</body>
</html>
`);
});

const PORT = process.env.PORT || 5000;
server.listen(PORT, () => {
  console.log(`==> Monolithic Local Plug Server live on port ${PORT}`);
});
