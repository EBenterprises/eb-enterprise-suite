const logger = require('../utils/logger');

const requestLogger = (req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const duration = Date.now() - start;
    logger.info(`${req.method} ${req.originalUrl} - Status: ${res.statusCode} - Duration: ${duration}ms`, {
      ip: req.ip,
      userAgent: req.get('user-agent')
    });
  });
  next();
};

module.exports = requestLogger;
