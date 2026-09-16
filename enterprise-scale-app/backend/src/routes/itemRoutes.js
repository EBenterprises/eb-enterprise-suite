const express = require('express');
const router = express.Router();
const { getItems, createItem } = require('../controllers/itemController');
const authMiddleware = require('../middleware/authMiddleware');

router.use(authMiddleware);
router.get('/', getItems);
router.post('/', createItem);

module.exports = router;
