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
