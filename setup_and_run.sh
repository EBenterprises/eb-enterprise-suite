#!/bin/bash
set -e

echo "==> Updating plug-monolith workspace..."
mkdir -p plug-monolith
cd plug-monolith

cat << 'INNER_EOF' > package.json
{
  "name": "plug-monolith",
  "version": "3.2.0",
  "description": "Monolithic secure plug messenger with instant message sync",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "bcryptjs": "^2.4.3",
    "cors": "^2.8.5",
    "dotenv": "^16.4.5",
    "express": "^4.19.2",
    "jsonwebtoken": "^9.0.2",
    "socket.io": "^4.7.5"
  }
}
INNER_EOF

npm install

cat << 'INNER_EOF' > server.js
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

app.get('/api/contacts/:userId/:role', async (req, res) => {
  try {
    const { userId, role } = req.params;
    const db = readDB();
    
    let contacts = [];
    if (role === 'plug' || role === 'admin') {
      contacts = db.users.filter(u => u._id !== userId);
    } else {
      contacts = db.users.filter(u => u.role === 'plug' || u.role === 'admin');
    }
    
    res.json(contacts.map(({ pin, ...u }) => u));
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
      const db = readDB();
      const message = {
        _id: data._id || 'msg_' + Date.now() + Math.random().toString(36).substring(2, 7),
        sender: data.sender,
        recipient: data.recipient,
        text: data.text,
        createdAt: data.createdAt || new Date().toISOString()
      };
      
      // Save to database permanently
      db.messages.push(message);
      writeDB(db);
      
      // Broadcast live to the recipient's room
      io.to(data.recipient).emit('receive_message', message);
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
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
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
  <div id="app" class="h-full flex flex-1 overflow-hidden"></div>
  <script>
    const socket = io();
    let currentUser = JSON.parse(localStorage.getItem('plug_user')) || null;
    let selectedContact = null;
    let messages = [];
    let contacts = [];
    let mobileView = 'contacts';

    // Global listener for incoming real-time transmissions from peers
    socket.on('receive_message', (msg) => {
      if (selectedContact && (msg.sender === selectedContact._id || msg.recipient === selectedContact._id)) {
        if (!messages.some(m => m._id === msg._id)) {
          messages.push(msg);
          renderChat();
        }
      } else {
        fetchContacts();
      }
    });

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
          fetchContacts();
          render();
        };
      } else {
        app.innerHTML = \`
          <div class="\${selectedContact && window.innerWidth < 768 && mobileView === 'chat' ? 'hidden' : 'flex'} w-full md:w-1/3 border-r border-gray-800 bg-cardBg flex-col h-full">
            <div class="p-4 border-b border-gray-800 flex justify-between items-center">
              <div>
                <div class="font-bold text-neonGreen">\${currentUser.username}</div>
                <div class="text-xs text-gray-500 uppercase">Role: \${currentUser.role}</div>
              </div>
              <button id="logout-btn" class="text-xs bg-gray-800 text-gray-300 px-3 py-1.5 rounded hover:bg-neonRed hover:text-white transition">Wipe Session</button>
            </div>
            <div class="p-3 bg-gray-900/40 text-xs font-bold text-gray-400 uppercase tracking-wider">
              \${currentUser.role === 'plug' ? 'Network Peers & Clients' : 'Available Plugs'}
            </div>
            <div id="contacts-list" class="flex-1 overflow-y-auto divide-y divide-gray-800/50"></div>
          </div>

          <div class="\${!selectedContact || (window.innerWidth < 768 && mobileView === 'contacts') ? 'hidden md:flex' : 'flex'} flex-1 flex-col bg-darkBg h-full w-full" id="chat-panel">
            <div class="flex-1 flex flex-col items-center justify-center text-gray-500 p-6 text-center">
              <p class="text-lg mb-2">Select a peer from the sidebar to open secure link.</p>
              <p class="text-xs text-gray-600">Encrypted peer-to-peer drop session active.</p>
            </div>
          </div>
        \`;

        document.getElementById('logout-btn').onclick = () => {
          localStorage.removeItem('plug_user');
          currentUser = null;
          selectedContact = null;
          render();
        };

        renderContacts();
        if (selectedContact) renderChat();
      }
    }

    function renderContacts() {
      const list = document.getElementById('contacts-list');
      if (!list) return;
      if (contacts.length === 0) {
        list.innerHTML = '<div class="p-4 text-center text-gray-500 text-sm">No active secure peers found.</div>';
        return;
      }
      list.innerHTML = contacts.map(c => \`
        <div onclick="selectContact('\${c._id}')" class="p-4 cursor-pointer transition flex items-center justify-between \${selectedContact?._id === c._id ? 'bg-gray-800/80 border-l-4 border-neonGreen' : 'hover:bg-gray-800/40'}">
          <div>
            <div class="font-semibold text-white">\${c.username} <span class="text-[10px] text-gray-400">[\${c.role}]</span></div>
            <div class="text-xs text-neonGreen">● Online & Ready</div>
          </div>
        </div>
      \`).join('');
    }

    async function selectContact(id) {
      selectedContact = contacts.find(c => c._id === id);
      mobileView = 'chat';
      render();
      const res = await fetch(\`/api/messages/\${currentUser._id}/\${selectedContact._id}\`);
      messages = await res.json();
      renderChat();
    }

    function renderChat() {
      const panel = document.getElementById('chat-panel');
      if (!panel || !selectedContact) return;
      panel.innerHTML = \`
        <div class="p-4 border-b border-gray-800 bg-cardBg flex justify-between items-center">
          <div class="flex items-center gap-3">
            <button id="back-btn" class="md:hidden text-neonGreen font-bold text-sm bg-gray-800/80 px-3 py-1 rounded">← Back</button>
            <div>
              <h2 class="font-bold text-white text-sm md:text-base">Tunnel: \${selectedContact.username}</h2>
              <span class="text-[10px] md:text-xs text-neonGreen">End-to-End Encrypted</span>
            </div>
          </div>
        </div>
        <div id="msg-container" class="flex-1 overflow-y-auto p-4 space-y-3">
          \${messages.map(m => \`
            <div class="flex \${m.sender === currentUser._id ? 'justify-end' : 'justify-start'}">
              <div class="max-w-[80%] md:max-w-md rounded-lg p-3 text-sm \${m.sender === currentUser._id ? 'bg-neonGreen text-darkBg font-medium' : 'bg-gray-800 text-gray-100'}">
                <p class="break-words">\${m.text}</p>
                <span class="block text-[10px] mt-1 text-right \${m.sender === currentUser._id ? 'text-gray-900' : 'text-gray-400'}">
                  \${new Date(m.createdAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                </span>
              </div>
            </div>
          \`).join('')}
        </div>
        <form id="msg-form" class="p-3 md:p-4 border-t border-gray-800 bg-cardBg flex gap-2">
          <input type="text" id="msg-input" autocomplete="off" placeholder="Type secure drop payload..." class="flex-1 bg-darkBg border border-gray-700 rounded p-3 text-white text-sm focus:outline-none focus:border-neonGreen">
          <button type="submit" class="bg-neonGreen text-darkBg font-bold px-4 md:px-6 rounded hover:bg-neonHover transition text-xs md:text-sm uppercase tracking-wider">Send</button>
        </form>
      \`;

      const backBtn = document.getElementById('back-btn');
      if (backBtn) {
        backBtn.onclick = () => {
          mobileView = 'contacts';
          selectedContact = null;
          render();
        };
      }

      const container = document.getElementById('msg-container');
      container.scrollTop = container.scrollHeight;

      document.getElementById('msg-form').onsubmit = (e) => {
        e.preventDefault();
        const input = document.getElementById('msg-input');
        const text = input.value.trim();
        if (!text) return;

        const payload = {
          _id: 'msg_' + Date.now() + Math.random().toString(36).substring(2, 7),
          sender: currentUser._id,
          recipient: selectedContact._id,
          text,
          createdAt: new Date().toISOString()
        };

        // Instantly push to local array & render
        messages.push(payload);
        renderChat();

        // Emit through socket to save on server and notify peer
        socket.emit('send_message', payload);
        input.value = '';
      };
    }

    async function fetchContacts() {
      if (!currentUser) return;
      const res = await fetch(\`/api/contacts/\${currentUser._id}/\${currentUser.role}\`);
      contacts = await res.json();
      renderContacts();
    }

    function initSocket() {
      if (!currentUser) return;
      socket.emit('join_room', currentUser._id);
    }

    if (currentUser) {
      initSocket();
      fetchContacts();
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
INNER_EOF

echo "==> Restarting server..."
npm start
