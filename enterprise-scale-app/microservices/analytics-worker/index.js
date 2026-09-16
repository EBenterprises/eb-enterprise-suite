const { createClient } = require('redis');
const { Pool } = require('pg');
require('dotenv').config();

const redisUrl = process.env.REDIS_URL || 'redis://localhost:6379';
const databaseUrl = process.env.DATABASE_URL || 'postgres://user:password@localhost:5432/enterprise_db';

const redisClient = createClient({ url: redisUrl });
const pgPool = new Pool({ connectionString: databaseUrl });

async function startWorker() {
  await redisClient.connect();
  console.log('[Analytics Worker] Connected to Redis queue stream.');

  setInterval(async () => {
    try {
      // Simulate processing async telemetry or event ingestion
      const timestamp = new Date().toISOString();
      await pgPool.query(
        'INSERT INTO items (user_id, name, metadata) VALUES ($1, $2, $3)',
        [1, `Telemetry Pulse @ ${timestamp}`, JSON.stringify({ worker: 'analytics-node-1', uptime: process.uptime() })]
      );
      console.log(`[Analytics Worker] Flushed telemetry batch pulse at ${timestamp}`);
    } catch (err) {
      console.error('[Analytics Worker] Processing cycle error:', err.message);
    }
  }, 15000);
}

startWorker().catch(console.error);
