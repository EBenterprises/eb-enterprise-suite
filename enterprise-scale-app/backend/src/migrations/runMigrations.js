const createUsersTable = require('./createUsersTable');
const createItemsTable = require('./createItemsTable');
const createTelemetryTable = require('./createTelemetryTable');
const logger = require('../utils/logger');
const db = require('../config/db');

async function run() {
  try {
    logger.info('[Migrations] Starting database migration sequence...');
    if (typeof createUsersTable === 'function') await createUsersTable();
    if (typeof createItemsTable === 'function') await createItemsTable();
    await createTelemetryTable();
    logger.info('[Migrations] All database migrations completed successfully.');
    process.exit(0);
  } catch (err) {
    logger.error('[Migrations] Fatal migration error:', err);
    process.exit(1);
  }
}

run();
