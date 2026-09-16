const express = require('express');
const http = require('http');
const cors = require('cors');
const { port } = require('./config/env');
const db = require('./config/db');
const logger = require('./utils/logger');
const requestLogger = require('./middleware/requestLogger');
const securityHeaders = require('./middleware/securityHeaders');
const errorHandler = require('./middleware/errorHandler');
const rateLimiter = require('./middleware/rateLimiter');
const { initWebSocket } = require('./websocket/socketServer');

const authRoutes = require('./routes/authRoutes');
const itemRoutes = require('./routes/itemRoutes');
const telemetryRoutes = require('./routes/telemetryRoutes');

const app = express();
const server = http.createServer(app);

initWebSocket(server);

app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(securityHeaders);
app.use(requestLogger);
app.use(rateLimiter({ windowMs: 60000, max: 200 }));

app.get('/health', async (req, res, next) => {
  try {
    const dbCheck = await db.query('SELECT NOW()');
    res.json({
      status: 'operational',
      uptime: process.uptime(),
      database: 'connected',
      dbTime: dbCheck.rows[0].now,
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    next(err);
  }
});

app.use('/api/auth', authRoutes);
app.use('/api/items', itemRoutes);
app.use('/api/telemetry', telemetryRoutes);

app.use(errorHandler);

server.listen(port, () => {
  logger.info(`Enterprise Server core fully loaded with telemetry routes on port ${port}`);
});
