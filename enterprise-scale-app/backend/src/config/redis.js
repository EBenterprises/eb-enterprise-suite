const { createClient } = require('redis');
const logger = require('../utils/logger');

const redisClient = createClient({
  url: process.env.REDIS_URL || 'redis://localhost:6379'
});

redisClient.on('error', (err) => logger.error('[Redis] Client Error', err));
redisClient.on('connect', () => logger.info('[Redis] Connected successfully to caching cluster'));

(async () => {
  try {
    await redisClient.connect();
  } catch (err) {
    logger.warn('[Redis] Initial connection deferred or failed:', err.message);
  }
})();

module.exports = redisClient;
