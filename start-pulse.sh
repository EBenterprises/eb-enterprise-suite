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
