const express = require('express');
const router = express.Router();
const telemetryController = require('../controllers/telemetryController');
const authenticateToken = require('../middleware/authenticateToken');

router.post('/', authenticateToken, telemetryController.ingest);
router.get('/', authenticateToken, telemetryController.list);

module.exports = router;
