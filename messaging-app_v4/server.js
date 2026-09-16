const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const path = require('path');
const { exec } = require('child_process');
const net = require('net');
<<<<<<< HEAD
=======
const fs = require('fs');
>>>>>>> b3a3620 (feat: release messaging-app_v4 with onion hidden service hooks, automated port scanning, and public tunneling)

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

// Automated Port Scanner function to bypass port collisions seamlessly
function findAvailablePort(startPort) {
    return new Promise((resolve, reject) => {
        const testServer = net.createServer();
        testServer.listen(startPort, () => {
            const port = testServer.address().port;
            testServer.close(() => resolve(port));
        });
        testServer.on('error', (err) => {
            if (err.code === 'EADDRINUSE') {
                console.log(`[!] Port ${startPort} in use, scanning next port...`);
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
        const url = `http://localhost:${PORT}`;
        console.log(`Messaging Server v4 running successfully on ${url}`);

        const openCmd = process.platform === 'win32' ? 'start' : process.platform === 'darwin' ? 'open' : 'xdg-open';
        exec(`${openCmd} ${url}`).on('error', () => {
            console.log(`Open your browser and navigate to: ${url}`);
        });

<<<<<<< HEAD
        // Automatically spawn a public tunnel using localtunnel so anyone can access it instantly via public link
=======
        // Automatically spawn a public tunnel using localtunnel
>>>>>>> b3a3620 (feat: release messaging-app_v4 with onion hidden service hooks, automated port scanning, and public tunneling)
        console.log(`[*] Generating public sharing link...`);
        const tunnelProcess = exec(`npx localtunnel --port ${PORT}`);
        
        tunnelProcess.stdout.on('data', (data) => {
            console.log(`[PUBLIC LINK]: ${data.toString().trim()}`);
        });

        tunnelProcess.stderr.on('data', (data) => {
            // Suppress minor tunnel warning outputs if any
        });
<<<<<<< HEAD
=======

        // Onion Link Generator Hook / Tor Hidden Service Config Guide
        console.log(`[*] Tor Onion Service Configuration Instructions:`);
        console.log(`    To generate a native .onion link, ensure Tor daemon is installed and configure your torrc:`);
        console.log(`    HiddenServiceDir /var/lib/tor/messaging_service/`);
        console.log(`    HiddenServicePort 80 127.0.0.1:${PORT}`);
        console.log(`    Then view your onion address using: sudo cat /var/lib/tor/messaging_service/hostname`);
>>>>>>> b3a3620 (feat: release messaging-app_v4 with onion hidden service hooks, automated port scanning, and public tunneling)
    });
}).catch((err) => {
    console.error('Failed to find an open port:', err);
    process.exit(1);
});
