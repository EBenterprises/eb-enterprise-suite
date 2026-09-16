const db = require('../config/db');
const logger = require('../utils/logger');

class TelemetryService {
  async recordEvent(eventType, payload) {
    try {
      const query = `
        INSERT INTO telemetry_events (event_type, payload, created_at)
        VALUES ($1, $2, NOW())
        RETURNING id, created_at
      `;
      const values = [eventType, JSON.stringify(payload)];
      const result = await db.query(query, values);
      return result.rows[0];
    } catch (err) {
      logger.error('[TelemetryService] Failed to record event:', err.message);
      throw err;
    }
  }

  async getRecentEvents(limit = 50) {
    try {
      const query = `
        SELECT id, event_type, payload, created_at
        FROM telemetry_events
        ORDER BY created_at DESC
        LIMIT $1
      `;
      const result = await db.query(query, [limit]);
      return result.rows;
    } catch (err) {
      logger.error('[TelemetryService] Failed to fetch telemetry events:', err.message);
      throw err;
    }
  }
}

module.exports = new TelemetryService();
