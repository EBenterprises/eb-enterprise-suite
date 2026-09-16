const db = require('../config/db');
const logger = require('../utils/logger');

async function createTelemetryTable() {
  try {
    await db.query(`
      CREATE TABLE IF NOT EXISTS telemetry_events (
        id SERIAL PRIMARY KEY,
        event_type VARCHAR(100) NOT NULL,
        payload JSONB NOT NULL DEFAULT '{}',
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
      CREATE INDEX IF NOT EXISTS idx_telemetry_event_type ON telemetry_events(event_type);
      CREATE INDEX IF NOT EXISTS idx_telemetry_created_at ON telemetry_events(created_at DESC);
    `);
    logger.info('[Migration] telemetry_events table and indexes verified/created.');
  } catch (err) {
    logger.error('[Migration] Failed to create telemetry_events table:', err.message);
    throw err;
  }
}

module.exports = createTelemetryTable;
