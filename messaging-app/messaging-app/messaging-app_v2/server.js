const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const path = require('path');
const { exec } = require('child_process');

const app = express();
const server = http.createServer(app);
const io = new Server(server);

app.use(express.static(path.join(__dirname, 'public')));

const activeUsers = new Set();

io.on('connection', (socket) => {
    console.log(`User connected: ${socket.id}`);

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
        io.emit('message', {
            user: socket.username || 'Anonymous',
            text: data.text,
            time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
        });
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

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
    const url = `http://localhost:${PORT}`;
    console.log(`Messaging Server v2 running on ${url}`);

    const openCmd = process.platform === 'win32' ? 'start' : process.platform === 'darwin' ? 'open' : 'xdg-open';
    exec(`${openCmd} ${url}`).on('error', () => {
        console.log(`Open your browser and navigate to: ${url}`);
    });
});
