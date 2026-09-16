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
app.use(express.json({ limit: '10mb' }));

// Initialize Multi-Room JSON Storage
const dbFile = path.join(__dirname, 'messages.json');
if (!fs.existsSync(dbFile)) {
    fs.writeFileSync(dbFile, JSON.stringify({ general: [], dev: [], random: [] }, null, 2));
}

function getDatabase() {
    try {
        const data = fs.readFileSync(dbFile, 'utf8');
        return JSON.parse(data);
    } catch (e) {
        return { general: [], dev: [], random: [] };
    }
}

function saveMessage(room, msg) {
    const db = getDatabase();
    if (!db[room]) db[room] = [];
    db[room].push(msg);
    if (db[room].length > 150) db[room].shift();
    fs.writeFileSync(dbFile, JSON.stringify(db, null, 2));
}

const activeUsers = new Map(); // socket.id -> { username, room }

io.on('connection', (socket) => {
    console.log(`User connected: ${socket.id}`);

    socket.on('join_room', ({ username, room }) => {
        if (socket.room) {
            socket.leave(socket.room);
        }

        socket.username = username;
        socket.room = room;
        socket.join(room);

        activeUsers.set(socket.id, { username, room });

        // Send room history
        const db = getDatabase();
        socket.emit('load_history', db[room] || []);

        // Broadcast user list for this room
        const roomUsers = Array.from(activeUsers.values())
            .filter(u => u.room === room)
            .map(u => u.username);

        io.to(room).emit('update_users', roomUsers);

        socket.broadcast.to(room).emit('message', {
            user: 'System',
            text: `${username} has joined #${room}.`,
            time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
        });
    });

    socket.on('chat_message', (data) => {
        if (!socket.room || !socket.username) return;

        const messagePayload = {
            user: socket.username,
            text: data.text,
            file: data.file || null,
            fileName: data.fileName || null,
            time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
        };

        saveMessage(socket.room, messagePayload);
        io.to(socket.room).emit('message', messagePayload);
    });

    socket.on('typing', (isTyping) => {
        if (socket.room && socket.username) {
            socket.broadcast.to(socket.room).emit('typing', { user: socket.username, isTyping });
        }
    });

    socket.on('disconnect', () => {
        const userInfo = activeUsers.get(socket.id);
        if (userInfo) {
            activeUsers.delete(socket.id);
            const roomUsers = Array.from(activeUsers.values())
                .filter(u => u.room === userInfo.room)
                .map(u => u.username);

            io.to(userInfo.room).emit('update_users', roomUsers);
            socket.broadcast.to(userInfo.room).emit('message', {
                user: 'System',
                text: `${userInfo.username} has left #${userInfo.room}.`,
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
