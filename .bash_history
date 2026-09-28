cd
cat << 'EOF' > eas.json
{
  "cli": {
    "version": ">= 0.52.0",
    "appVersionSource": "remote"
  },
  "build": {
    "development": {
      "developmentClient": true,
      "distribution": "internal"
    },
    "preview": {
      "distribution": "internal"
    },
    "production": {
      "android": {
        "buildType": "app-bundle"
      }
    }
  },
  "submit": {
    "production": {}
  }
}
EOF

eas build --platform android --profile production
cat << 'EOF' > eas.json
{
  "cli": {
    "version": ">= 0.52.0",
    "appVersionSource": "remote"
  },
  "build": {
    "development": {
      "developmentClient": true,
      "distribution": "internal"
    },
    "preview": {
      "distribution": "internal"
    },
    "production": {
      "android": {
        "buildType": "app-bundle"
      }
    }
  },
  "submit": {
    "production": {}
  }
}
EOF

mkdir -p eb-enterprises-tap-app/{src/{api,models,views},public/assets,data}
cd eb-enterprises-tap-app
# Create package.json
cat << 'EOF' > package.json
{
  "name": "tap-eco-live",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "start": "node src/server.js"
  },
  "dependencies": {
    "express": "^4.19.2",
    "dotenv": "^16.4.5"
  }
}
EOF

# Create Database Model
cat << 'EOF' > src/models/db.js
const fs = require('fs');
const path = require('path');

const dataDir = path.join(__dirname, '../../data');
const dbFile = path.join(dataDir, 'tap-members.json');

if (!fs.existsSync(dataDir)) {
    fs.mkdirSync(dataDir, { recursive: true });
}

if (!fs.existsSync(dbFile)) {
    fs.writeFileSync(dbFile, JSON.stringify([
        { id: 1, email: 'eastonbodeuxenterprises@gmail.com', role: 'FOUNDER', joined: new Date().toISOString() },
        { id: 2, email: 'pioneer@tap.eco', role: 'AFFILIATE', joined: new Date().toISOString() }
    ], null, 2));
}

module.exports = {
    getMembers: () => JSON.parse(fs.readFileSync(dbFile, 'utf8')),
    addMember: (email) => {
        const members = JSON.parse(fs.readFileSync(dbFile, 'utf8'));
        const newMember = { id: members.length + 1, email, role: 'AFFILIATE', joined: new Date().toISOString() };
        members.push(newMember);
        fs.writeFileSync(dbFile, JSON.stringify(members, null, 2));
        return newMember;
    }
};
EOF

# Create Express Server
cat << 'EOF' > src/server.js
const express = require('express');
const path = require('path');
const db = require('./models/db');

const app = express();
const PORT = process.env.PORT || 14001;

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, '../public')));

app.get('/', (req, res) => {
    const members = db.getMembers();
    res.send(`
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>www.tap.eco — Live Affiliate & Community Platform</title>
            <style>
                :root { --bg: #010409; --card: #0d1117; --accent: #3fb950; --text: #f0f6fc; --muted: #8b949e; --border: #30363d; font-family: monospace; }
                body { background: var(--bg); color: var(--text); margin: 0; padding: 2rem; display: flex; justify-content: center; }
                .container { width: 100%; max-width: 700px; }
                .card { background: var(--card); border: 1px solid var(--border); border-radius: 8px; padding: 2rem; margin-bottom: 1.5rem; }
                h1 { color: var(--accent); margin-top: 0; font-size: 1.8rem; }
                p { color: var(--muted); line-height: 1.5; }
                input, button { width: 100%; padding: 0.8rem; margin-top: 1rem; background: var(--bg); border: 1px solid var(--border); color: var(--text); border-radius: 6px; font-family: monospace; box-sizing: border-box; }
                button { background: var(--accent); color: #010409; font-weight: bold; cursor: pointer; text-transform: uppercase; }
                button:hover { background: #56d364; }
                ul { list-style: none; padding: 0; margin-top: 1rem; }
                li { background: var(--bg); border: 1px solid var(--border); padding: 0.6rem 1rem; border-radius: 4px; margin-bottom: 0.5rem; display: flex; justify-content: space-between; font-size: 0.85rem; }
                .badge { color: var(--accent); }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="card">
                    <h1>www.tap.eco</h1>
                    <p>Live affiliate network onboarding platform. Register your email below to instantly join the active node network managed under EB Enterprises®.</p>
                    <form action="/api/register" method="POST">
                        <input type="email" name="email" placeholder="Enter your email address..." required>
                        <button type="submit">Join Affiliate Network</button>
                    </form>
                </div>
                <div class="card">
                    <h3>Active Network Members (${members.length})</h3>
                    <ul>
                        ${members.map(m => `<li><span>${m.email}</span> <span class="badge">[${m.role}]</span></li>`).join('')}
                    </ul>
                </div>
            </div>
        </body>
        </html>
    `);
});

app.post('/api/register', (req, res) => {
    const { email } = req.body;
    if (email) {
        db.addMember(email);
    }
    res.redirect('/');
});

app.listen(PORT, () => {
    console.log(`[EB Enterprises] Tap platform live on port ${PORT}`);
});
EOF

# Install dependencies and start live deployment
npm install
npm start
mkdir -p eb-enterprise-core/{config,src/{api,models,views,core},public/assets,scripts,deploy}
cd eb-enterprise-core
# 1. Package Configuration
cat << 'EOF' > package.json
{
  "name": "eb-enterprise-core",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "start": "node src/server.js",
    "deploy": "node scripts/deploy.js"
  },
  "dependencies": {
    "express": "^4.19.2",
    "dotenv": "^16.4.5"
  }
}
EOF

# 2. Deployment Trigger Script
cat << 'EOF' > scripts/deploy.js
const { execSync } = require('child_process');

console.log('[EB Enterprises] Initializing live deployment trigger...');
try {
    console.log('[1/2] Verifying system dependencies...');
    execSync('npm install', { stdio: 'inherit' });
    console.log('[2/2] Triggering live server startup...');
    execSync('node src/server.js', { stdio: 'inherit' });
} catch (error) {
    console.error('[Deployment Error]', error.message);
    process.exit(1);
}
EOF

# 3. Core Database Model & Credentials Manager
cat << 'EOF' > src/models/db.js
const fs = require('fs');
const path = require('path');

const dataDir = path.join(__dirname, '../../data');
const dbFile = path.join(dataDir, 'enterprise-registry.json');

if (!fs.existsSync(dataDir)) {
    fs.mkdirSync(dataDir, { recursive: true });
}

if (!fs.existsSync(dbFile)) {
    fs.writeFileSync(dbFile, JSON.stringify({
        organization: "EB Enterprises",
        credentialsFetched: true,
        nodes: [
            { id: 1, name: "www.tap.eco", type: "Affiliate Platform", status: "ACTIVE" },
            { id: 2, name: "BuySideOnline", type: "Web Interface", status: "ACTIVE" },
            { id: 3, name: "CoinScan", type: "Identifier Engine", status: "READY" }
        ],
        updatedAt: new Date().toISOString()
    }, null, 2));
}

module.exports = {
    getRegistry: () => JSON.parse(fs.readFileSync(dbFile, 'utf8')),
    updateRegistry: (data) => {
        fs.writeFileSync(dbFile, JSON.stringify(data, null, 2));
    }
};
EOF

# 4. Main Express Server & Dashboard Logic
cat << 'EOF' > src/server.js
const express = require('express');
const path = require('path');
const db = require('./models/db');

const app = express();
const PORT = process.env.PORT || 14002;

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, '../public')));

app.get('/', (req, res) => {
    const registry = db.getRegistry();
    res.send(`
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>EB Enterprises — Full-Stack Command Center</title>
            <style>
                :root { --bg: #0d1117; --card: #161b22; --accent: #238636; --text: #c9d1d9; --muted: #8b949e; --border: #30363d; font-family: monospace; }
                body { background: var(--bg); color: var(--text); margin: 0; padding: 2rem; display: flex; justify-content: center; }
                .container { width: 100%; max-width: 800px; }
                .card { background: var(--card); border: 1px solid var(--border); border-radius: 6px; padding: 1.5rem; margin-bottom: 1rem; }
                h1 { color: #58a6ff; margin-top: 0; }
                ul { list-style: none; padding: 0; }
                li { background: var(--bg); border: 1px solid var(--border); padding: 0.75rem; border-radius: 4px; margin-top: 0.5rem; display: flex; justify-content: space-between; }
                .badge { color: var(--accent); font-weight: bold; }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="card">
                    <h1>EB Enterprises Command Center</h1>
                    <p>Automated Full-Stack Node & Affiliate Infrastructure</p>
                </div>
                <div class="card">
                    <h3>Registered Ecosystem Nodes</h3>
                    <ul>
                        ${registry.nodes.map(n => `<li><span><strong>${n.name}</strong> (${n.type})</span> <span class="badge">[${n.status}]</span></li>`).join('')}
                    </ul>
                </div>
            </div>
        </body>
        </html>
    `);
});

app.listen(PORT, () => {
    console.log(`[EB Enterprises] Command center running on port ${PORT}`);
});
EOF

# 5. Execute Live Deployment Trigger Automatically
npm run deploy
cd
cat << 'EOF' > start-pulse.sh
#!/bin/bash
set -e

echo "🚀 Initializing Pulse Platform..."
mkdir -p server/src server/prisma mobile/src/screens

echo "📦 Writing backend schema & server..."
cat << 'EOT' > server/prisma/schema.prisma
datasource db {
  provider = "sqlite"
  url      = "file:./dev.db"
}
generator client {
  provider = "prisma-client-js"
}
model User {
  id        String   @id @default(uuid())
  username  String   @unique
  bio       String?
  avatar    String?
  createdAt DateTime @default(now())
  swipesSent     Swipe[] @relation("SwipesSent")
  swipesReceived Swipe[] @relation("SwipesReceived")
  posts          Post[]
  stories        Story[]
  messages       Message[]
}
model Swipe {
  id         String   @id @default(uuid())
  fromUserId String
  toUserId   String
  action     String
  createdAt  DateTime @default(now())
  fromUser User @relation("SwipesSent", fields: [fromUserId], references: [id])
  toUser   User @relation("SwipesReceived", fields: [toUserId], references: [id])
  @@unique([fromUserId, toUserId])
}
model Post {
  id        String   @id @default(uuid())
  userId    String
  mediaUrl  String
  caption   String?
  likes     Int      @default(0)
  createdAt DateTime @default(now())
  user User @relation(fields: [userId], references: [id])
}
model Story {
  id        String   @id @default(uuid())
  userId    String
  mediaUrl  String
  expiresAt DateTime
  createdAt DateTime @default(now())
  user User @relation(fields: [userId], references: [id])
}
model Message {
  id         String   @id @default(uuid())
  senderId   String
  receiverId String
  text       String?
  mediaUrl   String?
  isEphemeral Boolean @default(false)
  isOpened   Boolean  @default(false)
  createdAt  DateTime @default(now())
  sender User @relation(fields: [senderId], references: [id])
}
EOT

cat << 'EOT' > server/package.json
{
  "name": "pulse-server",
  "version": "1.0.0",
  "main": "src/index.js",
  "scripts": {
    "dev": "npx prisma db push && node src/index.js"
  },
  "dependencies": {
    "@prisma/client": "^5.0.0",
    "cors": "^2.8.5",
    "express": "^4.18.2",
    "socket.io": "^4.7.2"
  },
  "devDependencies": {
    "prisma": "^5.0.0"
  }
}
EOT

cat << 'EOT' > server/src/index.js
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const { PrismaClient } = require('@prisma/client');
const cors = require('cors');

const prisma = new PrismaClient();
const app = express();
const server = http.createServer(app);
const io = new Server(server, { cors: { origin: '*' } });

app.use(cors());
app.use(express.json());
app.use('/uploads', express.static('uploads'));

app.post('/api/auth/login', async (req, res) => {
  const { username } = req.body;
  let user = await prisma.user.findUnique({ where: { username } });
  if (!user) {
    user = await prisma.user.create({ data: { username, bio: "New on Pulse" } });
  }
  res.json(user);
});

app.get('/api/users/:userId/discover', async (req, res) => {
  const { userId } = req.params;
  const swiped = await prisma.swipe.findMany({
    where: { fromUserId: userId },
    select: { toUserId: true },
  });
  const excludedIds = [userId, ...swiped.map(s => s.toUserId)];
  const users = await prisma.user.findMany({
    where: { id: { notIn: excludedIds } },
    take: 10,
  });
  res.json(users);
});

app.post('/api/swipe', async (req, res) => {
  const { fromUserId, toUserId, action } = req.body;
  const swipe = await prisma.swipe.create({
    data: { fromUserId, toUserId, action }
  });

  let isMatch = false;
  if (action === 'LIKE') {
    const reciprocal = await prisma.swipe.findUnique({
      where: { fromUserId_toUserId: { fromUserId: toUserId, toUserId: fromUserId } }
    });
    if (reciprocal && reciprocal.action === 'LIKE') {
      isMatch = true;
    }
  }
  res.json({ swipe, isMatch });
});

app.get('/api/posts', async (req, res) => {
  const posts = await prisma.post.findMany({
    include: { user: true },
    orderBy: { createdAt: 'desc' }
  });
  res.json(posts);
});

app.get('/api/stories', async (req, res) => {
  const now = new Date();
  const stories = await prisma.story.findMany({
    where: { expiresAt: { gt: now } },
    include: { user: true }
  });
  res.json(stories);
});

io.on('connection', (socket) => {
  console.log('User connected:', socket.id);

  socket.on('join_room', (userId) => {
    socket.join(userId);
  });

  socket.on('send_message', async (data) => {
    const { senderId, receiverId, text, mediaUrl, isEphemeral } = data;
    const message = await prisma.message.create({
      data: { senderId, receiverId, text, mediaUrl, isEphemeral }
    });
    io.to(receiverId).emit('receive_message', message);
  });

  socket.on('disconnect', () => {
    console.log('User disconnected:', socket.id);
  });
});

const PORT = process.env.PORT || 4000;
server.listen(PORT, () => console.log(`🚀 Pulse Server running on port ${PORT}`));
EOT

cd server && npm install && cd ..

echo "✨ Pulse Setup Complete!"
echo "To start your backend server, run:"
echo "cd server && npm run dev"
EOF

chmod +x start-pulse.sh
./start-pulse.sh
