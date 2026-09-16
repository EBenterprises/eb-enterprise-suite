const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const path = require('path');
const { exec } = require('child_process');
const net = require('net');
<<<<<<< HEAD
=======
const https = require('https');
>>>>>>> 7422356 (feat: release messaging-app_v4 with direct public link output and automatic port collision avoidance)

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

<<<<<<< HEAD
// Automated Port Scanner function to bypass port collisions seamlessly
=======
>>>>>>> 7422356 (feat: release messaging-app_v4 with direct public link output and automatic port collision avoidance)
function findAvailablePort(startPort) {
    return new Promise((resolve, reject) => {
        const testServer = net.createServer();
        testServer.listen(startPort, () => {
            const port = testServer.address().port;
            testServer.close(() => resolve(port));
        });
        testServer.on('error', (err) => {
            if (err.code === 'EADDRINUSE') {
<<<<<<< HEAD
                console.log(`[!] Port ${startPort} in use, scanning next port...`);
=======
>>>>>>> 7422356 (feat: release messaging-app_v4 with direct public link output and automatic port collision avoidance)
                resolve(findAvailablePort(startPort + 1));
            } else {
                reject(err);
            }
        });
    });
}

<<<<<<< HEAD
=======
function getPublicIp(callback) {
    https.get('https://api.ipify.org?format=json', (res) => {
        let data = '';
        res.on('data', (chunk) => { data += chunk; });
        res.on('end', () => {
            try {
                const parsed = JSON.parse(data);
                callback(parsed.ip);
            } catch (e) {
                callback(null);
            }
        });
    }).on('error', () => {
        callback(null);
    });
}

>>>>>>> 7422356 (feat: release messaging-app_v4 with direct public link output and automatic port collision avoidance)
const INITIAL_PORT = process.env.PORT ? parseInt(process.env.PORT) : 3000;

findAvailablePort(INITIAL_PORT).then((PORT) => {
    server.listen(PORT, () => {
<<<<<<< HEAD
        const url = `http://localhost:${PORT}`;
        console.log(`Messaging Server v4 running successfully on ${url}`);

        const openCmd = process.platform === 'win32' ? 'start' : process.platform === 'darwin' ? 'open' : 'xdg-open';
        exec(`${openCmd} ${url}`).on('error', () => {
            console.log(`Open your browser and navigate to: ${url}`);
        });

        // Automatically spawn a public tunnel using localtunnel so anyone can access it instantly via public link
        console.log(`[*] Generating public sharing link...`);
        const tunnelProcess = exec(`npx localtunnel --port ${PORT}`);
        
        tunnelProcess.stdout.on('data', (data) => {
            console.log(`[PUBLIC LINK]: ${data.toString().trim()}`);
        });

        tunnelProcess.stderr.on('data', (data) => {
            // Suppress minor tunnel warning outputs if any
        });
    });
}).catch((err) => {
    console.error('Failed to find an open port:', err);
=======
        const localUrl = `http://localhost:${PORT}`;
        console.log(`\n==================================================`);
        console.log(`[+] Local URL: ${localUrl}`);

        getPublicIp((ip) => {
            if (ip) {
                console.log(`[+] Network URL: http://${ip}:${PORT}`);
            }
            console.log(`==================================================\n`);
        });

        const openCmd = process.platform === 'win32' ? 'start' : process.platform === 'darwin' ? 'open' : 'xdg-open';
        exec(`${openCmd} ${localUrl}`).on('error', () => {});

        console.log(`[*] Establishing live public tunnel (localtunnel)...`);
        const tunnelProcess = exec(`npx localtunnel --port ${PORT}`);

        tunnelProcess.stdout.on('data', (data) => {
            const output = data.toString().trim();
            if (output.startsWith('https://') || output.startsWith('http://')) {
                console.log(`\n==================================================`);
                console.log(`[★] LIVE PUBLIC LINK: ${output}`);
                console.log(`==================================================\n`);
            } else {
                console.log(output);
            }
        });
    });
}).catch((err) => {
    console.error('Failed to initialize server:', err);
>>>>>>> 7422356 (feat: release messaging-app_v4 with direct public link output and automatic port collision avoidance)
    process.exit(1);
});
