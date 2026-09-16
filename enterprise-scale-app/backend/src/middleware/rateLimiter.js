const redisClient = require('../config/redis');
const logger = require('../utils/logger');

const rateLimiter = (options = { windowMs: 60000, max: 100 }) => {
  return async (req, res, next) => {
    try {
      const ip = req.ip || req.connection.remoteAddress;
      const key = `ratelimit:${ip}`;

      const current = await redisClient.incr(key);
      if (current === 1) {
        await redisClient.pExpire(key, options.windowMs);
      }

      if (current > options.max) {
        logger.warn(`[RateLimiter] Threshold exceeded for IP: ${ip}`);
        return res.status(429).json({
          success: false,
          error: 'Too many requests, please try again later.',
          retryAfter: Math.ceil(options.windowMs / 1000)
        });
      }

      res.setHeader('X-RateLimit-Limit', options.max);
      res.setHeader('X-RateLimit-Remaining', Math.max(0, options.max - current));
      next();
    } catch (err) {
      // Fail open if Redis drops under heavy pressure
      logger.error('[RateLimiter] Redis failure, bypassing check:', err.message);
      next();
    }
  };
};

module.exports = rateLimiter;
