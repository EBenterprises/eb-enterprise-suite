const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');

const isAuthenticated = (req, res, next) => {
  if (req.session && req.session.userId) {
    return next();
  }
  res.redirect('/login');
};

router.get('/dashboard', isAuthenticated, userController.getDashboard);
router.get('/settings', isAuthenticated, userController.getSettings);
router.get('/api/user', isAuthenticated, userController.getProfileData);
router.post('/api/settings', isAuthenticated, userController.updateSettings);

module.exports = router;
