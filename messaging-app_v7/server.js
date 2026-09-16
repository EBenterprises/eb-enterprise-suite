const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const path = require('path');
const { exec } = require('child_process');
const net = require('net');
const fs = require('fs');
const crypto = require('crypto');

const app = express();
const server = http.createServer(app);
const io = new Server(server);

app.use(express.static(path.join(__dirname, 'public')));
app.use(express.json({ limit: '25mb' }));
app.use(express.urlencoded({ extended: true }));

// Initialize Advanced Multi-Room, DM & Auth JSON Storage
const dbFile = path.join(__dirname, 'database.json');
if (!fs.existsSync(dbFile)) {
    fs.writeFileSync(dbFile, JSON.stringify({ 
        rooms: { general: [], dev: [], random: [], watercooler: [] },
        directMessages: {},
        users: {} // username -> { passwordHash, createdAt }
    }, null, 2));
}

function getDatabase() {
    try {
        const data = fs.readFileSync(dbFile, 'utf8');
        return JSON.parse(data);
    } catch (e) {
        return { rooms: { general: [], dev: [], random: [], watercooler: [] }, directMessages: {}, users: {} };
    }
}

function saveDatabase(db) {
    fs.writeFileSync(dbFile, JSON.stringify(db, null, 2));
}

function hashPassword(password) {
    return crypto.createHash('sha256').update(password).digest('hex');
}

// Authentication REST Endpoints
app.post('/api/register', (req, res) => {
    const { username, password } = req.body;
    if (!username || !password || username.trim().length < 2 || password.length < 4) {
        return res.status(400).json({ success: false, error: 'Username (min 2 chars) and password (min 4 chars) required.' });
    }

    const cleanUser = username.trim();
    const db = getDatabase();

    if (db.users[cleanUser]) {
        return res.status(400).json({ success: false, error: 'Username already taken.' });
    }

    db.users[cleanUser] = {
        passwordHash: hashPassword(password),
        createdAt: new Date().toISOString()
    };
    saveDatabase(db);

    return res.json({ success: true, username: cleanUser });
});

app.post('/api/login', (req, res) => {
    const { username, password } = req.body;
    if (!username || !password) {
        return res.status(400).json({ success: false, error: 'Username and password required.' });
    }

    const cleanUser = username.trim();
    const db = getDatabase();
    const userRecord = db.users[cleanUser];

    if (!userRecord || userRecord.passwordHash !== hashPassword(password)) {
        return res.status(401).json({ success: false, error: 'Invalid username or password.' });
    }

    return res.json({ success: true, username: cleanUser });
});

function saveRoomMessage(room, msg) {
    const db = getDatabase();
    if (!db.rooms[room]) db.rooms[room] = [];
    db.rooms[room].push(msg);
    if (db.rooms[room].length > 200) db.rooms[room].shift();
    saveDatabase(db);
}

function saveDirectMessage(user1, user2, msg) {
    const db = getDatabase();
    const key = [user1, user2].sort().join(':');
    if (!db.directMessages[key]) db.directMessages[key] = [];
    db.directMessages[key].push(msg);
    if (db.directMessages[key].length > 200) db.directMessages[key].shift();
    saveDatabase(db);
}

const activeUsers = new Map(); // socket.id -> { username, currentRoom, targetUser }

io.on('connection', (socket) => {
    console.log(`User connected: ${socket.id}`);

    socket.on('register_session', (username) => {
        if (!username) return;
        socket.username = username;
        activeUsers.set(socket.id, { username, currentRoom: 'general', targetUser: null });
        
        const allUsers = Array.from(activeUsers.values()).map(u => u.username);
        io.emit('update_global_users', Array.from(new Set(allUsers)));
    });

    socket.on('join_room', (room) => {
        if (!socket.username) return;
        if (socket.currentRoom) socket.leave(socket.currentRoom);

        socket.currentRoom = room;
        socket.targetUser = null;
        socket.join(room);

        const userInfo = activeUsers.get(socket.id);
        if (userInfo) {
            userInfo.currentRoom = room;
            userInfo.targetUser = null;
        }

        const db = getDatabase();
        socket.emit('load_history', db.rooms[room] || []);

        const roomUsers = Array.from(activeUsers.values())
            .filter(u => u.currentRoom === room)
            .map(u => u.username);
        io.to(room).emit('update_room_users', Array.from(new Set(roomUsers)));
    });

    socket.on('join_dm', (targetUser) => {
        if (!socket.username) return;
        if (socket.currentRoom) socket.leave(socket.currentRoom);

        socket.currentRoom = null;
        socket.targetUser = targetUser;

        const userInfo = activeUsers.get(socket.id);
        if (userInfo) {
            userInfo.currentRoom = null;
            userInfo.targetUser = targetUser;
        }

        const db = getDatabase();
        const key = [socket.username, targetUser].sort().join(':');
        socket.emit('load_history', db.directMessages[key] || []);
    });

    socket.on('chat_message', (data) => {
        if (!socket.username) return;

        const messagePayload = {
            id: Date.now().toString() + Math.random().toString(36).slice(2, 7),
            user: socket.username,
            text: data.text,
            file: data.file || null,
            fileName: data.fileName || null,
            reactions: {},
            time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
        };

        if (socket.currentRoom) {
            saveRoomMessage(socket.currentRoom, messagePayload);
            io.to(socket.currentRoom).emit('message', messagePayload);
        } else if (socket.targetUser) {
            saveDirectMessage(socket.username, socket.targetUser, messagePayload);
            socket.emit('message', messagePayload);

            for (let [id, userObj] of activeUsers.entries()) {
                if (userObj.username === socket.targetUser && (userObj.targetUser === socket.username || userObj.currentRoom === null)) {
                    io.to(id).emit('message', messagePayload);
                }
            }
        }
    });

    socket.on('add_reaction', ({ messageId, emoji, room, targetUser }) => {
        const db = getDatabase();
        let messages = [];

        if (room) {
            messages = db.rooms[room] || [];
        } else if (targetUser) {
            const key = [socket.username, targetUser].sort().join(':');
            messages = db.directMessages[key] || [];
        }

        const msg = messages.find(m => m.id === messageId);
        if (msg) {
            if (!msg.reactions[emoji]) msg.reactions[emoji] = [];
            if (!msg.reactions[emoji].includes(socket.username)) {
                msg.reactions[emoji].push(socket.username);
            } else {
                msg.reactions[emoji] = msg.reactions[emoji].filter(u => u !== socket.username);
                if (msg.reactions[emoji].length === 0) delete msg.reactions[emoji];
            }
            saveDatabase(db);

            if (room) {
                io.to(room).emit('update_reactions', { messageId, reactions: msg.reactions });
            } else if (targetUser) {
                socket.emit('update_reactions', { messageId, reactions: msg.reactions });
                for (let [id, userObj] of activeUsers.entries()) {
                    if (userObj.username === targetUser) {
                        io.to(id).emit('update_reactions', { messageId, reactions: msg.reactions });
                    }
                }
            }
        }
    });

    socket.on('typing', (isTyping) => {
        if (socket.currentRoom && socket.username) {
            socket.broadcast.to(socket.currentRoom).emit('typing', { user: socket.username, isTyping });
        }
    });

    socket.on('disconnect', () => {
        const userInfo = activeUsers.get(socket.id);
        if (userInfo) {
            activeUsers.delete(socket.id);
            const allUsers = Array.from(activeUsers.values()).map(u => u.username);
            io.emit('update_global_users', Array.from(new Set(allUsers)));

            if (userInfo.currentRoom) {
                const roomUsers = Array.from(activeUsers.values())
                    .filter(u => u.currentRoom === userInfo.currentRoom)
                    .map(u => u.username);
                io.to(userInfo.currentRoom).emit('update_room_users', Array.from(new Set(roomUsers)));
            }
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
