const { createClient } = require('redis');
require('dotenv').config();

const redisClient = createClient({ url: process.env.REDIS_URL || 'redis://localhost:6379' });

async function startNotificationWorker() {
  await redisClient.connect();
  console.log('[Notification Worker] Operational and listening for event triggers.');

  // Subscribe to internal pub/sub channels or evaluate event streams
  await redisClient.subscribe('enterprise_events', (message) => {
    console.log(`[Notification Worker] Event intercepted & dispatched:`, message);
  });
}

startNotificationWorker().catch(console.error);
