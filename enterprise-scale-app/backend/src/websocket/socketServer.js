const { Server } = require('socket.io');
const logger = require('../utils/logger');
const jwt = require('jsonwebtoken');
const { jwtSecret } = require('../config/env');

let ioInstance = null;

const initWebSocket = (server) => {
  ioInstance = new Server(server, {
    cors: {
      origin: '*',
      methods: ['GET', 'POST']
    }
  });

  ioInstance.use((socket, next) => {
    const token = socket.handshake.auth.token || socket.handshake.headers['authorization'];
    if (!token) {
      return next(new Error('Authentication error: Token missing'));
    }
    const cleanToken = token.startsWith('Bearer ') ? token.slice(7) : token;
    jwt.verify(cleanToken, jwtSecret, (err, decoded) => {
      if (err) return next(new Error('Authentication error: Invalid token'));
      socket.user = decoded;
      next();
    });
  });

  ioInstance.on('connection', (socket) => {
    logger.info(`[WebSocket] Client connected: ID ${socket.id}, User: ${socket.user.email}`);
    
    socket.join(`user_${socket.user.id}`);

    socket.on('client_ping', (data) => {
      socket.emit('server_pong', { timestamp: new Date().toISOString(), echo: data });
    });

    socket.on('disconnect', () => {
      logger.info(`[WebSocket] Client disconnected: ID ${socket.id}`);
    });
  });

  logger.info('[WebSocket] Real-time engine successfully attached to server core.');
  return ioInstance;
};

const getIO = () => {
  if (!ioInstance) throw new Error('Socket.io not initialized');
  return ioInstance;
};

module.exports = { initWebSocket, getIO };
