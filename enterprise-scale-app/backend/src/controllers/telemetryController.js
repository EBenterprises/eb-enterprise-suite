const telemetryService = require('../services/telemetryService');
const logger = require('../utils/logger');

class TelemetryController {
  async ingest(req, res, next) {
    try {
      const { eventType, payload } = req.body;
      if (!eventType) {
        return res.status(400).json({ success: false, error: 'eventType is required' });
      }

      const event = await telemetryService.recordEvent(eventType, payload || {});
      return res.status(201).json({ success: true, data: event });
    } catch (err) {
      next(err);
    }
  }

  async list(req, res, next) {
    try {
      const limit = parseInt(req.query.limit, 10) || 50;
      const events = await telemetryService.getRecentEvents(limit);
      return res.json({ success: true, count: events.length, data: events });
    } catch (err) {
      next(err);
    }
  }
}

module.exports = new TelemetryController();
