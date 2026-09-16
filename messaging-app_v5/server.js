const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const path = require('path');
const { exec } = require('child_process');
const net = require('net');
const fs = require('fs');

const app = express();
const server = http.createServer(app);
const io = new Server(server);

app.use(express.static(path.join(__dirname, 'public')));
app.use(express.json());

// Initialize Zero-Dependency JSON File Storage
const dbFile = path.join(__dirname, 'messages.json');
if (!fs.existsSync(dbFile)) {
    fs.writeFileSync(dbFile, JSON.stringify([], null, 2));
}

function getMessages() {
    try {
        const data = fs.readFileSync(dbFile, 'utf8');
        return JSON.parse(data);
    } catch (e) {
        return [];
    }
}

function saveMessage(msg) {
    const messages = getMessages();
    messages.push(msg);
    if (messages.length > 100) messages.shift(); // Keep last 100 messages
    fs.writeFileSync(dbFile, JSON.stringify(messages, null, 2));
}

const activeUsers = new Set();

io.on('connection', (socket) => {
    console.log(`User connected: ${socket.id}`);

    // Send recent history upon connection
    const history = getMessages();
    socket.emit('load_history', history);

    socket.on('join', (username) => {
        socket.username = username;
        activeUsers.add(username);
        io.emit('update_users', Array.from(activeUsers));
        socket.broadcast.emit('message', {
            user: 'System',
            text: `${username} has joined the chat.`,
            time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
        });
    });

    socket.on('chat_message', (data) => {
        const messagePayload = {
            user: socket.username || 'Anonymous',
            text: data.text,
            time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
        };

        saveMessage(messagePayload);
        io.emit('message', messagePayload);
    });

    socket.on('typing', (isTyping) => {
        if (socket.username) {
            socket.broadcast.emit('typing', { user: socket.username, isTyping });
        }
    });

    socket.on('disconnect', () => {
        if (socket.username) {
            activeUsers.delete(socket.username);
            io.emit('update_users', Array.from(activeUsers));
            socket.broadcast.emit('message', {
                user: 'System',
                text: `${socket.username} has left the chat.`,
                time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
            });
        }
        console.log(`User disconnected: ${socket.id}`);
    });
});

function findAvailablePort(startPort) {
    return new Promise((resolve, reject) => {
        const testServer = net.createServer();
        testServer.listen(startPort, () => {
            const port = testServer.address().port;
            testServer.close(() => resolve(port));
        });
        testServer.on('error', (err) => {
            if (err.code === 'EADDRINUSE') {
                resolve(findAvailablePort(startPort + 1));
            } else {
                reject(err);
            }
        });
    });
}

const INITIAL_PORT = process.env.PORT ? parseInt(process.env.PORT) : 3000;

findAvailablePort(INITIAL_PORT).then((PORT) => {
    server.listen(PORT, () => {
        const localUrl = `http://localhost:${PORT}`;
        console.log(`\n==================================================`);
        console.log(`[+] LOCAL URL   : ${localUrl}`);
        console.log(`==================================================\n`);

        const openCmd = process.platform === 'win32' ? 'start' : process.platform === 'darwin' ? 'open' : 'xdg-open';
        exec(`${openCmd} ${localUrl}`).on('error', () => {});

        console.log(`[*] Spawning Live Public Tunnel (localtunnel)...`);
        const tunnelProcess = exec(`npx localtunnel --port ${PORT}`);

        tunnelProcess.stdout.on('data', (data) => {
            const output = data.toString().trim();
            if (output.startsWith('https://') || output.startsWith('http://')) {
                console.log(`\n==================================================`);
                console.log(`[★] PUBLIC URL  : ${output}`);
                console.log(`==================================================\n`);
            }
        });
    });
}).catch((err) => {
    console.error('Failed to initialize server:', err);
    process.exit(1);
});
