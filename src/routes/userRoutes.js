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
router.get('/analytics', isAuthenticated, userController.getAnalytics);
router.get('/api/user', isAuthenticated, userController.getProfileData);
router.post('/api/settings', isAuthenticated, userController.updateSettings);
router.post('/api/2fa/setup', isAuthenticated, userController.setup2fa);
router.post('/api/2fa/verify', isAuthenticated, userController.verifyAndEnable2fa);
router.post('/api/2fa/disable', isAuthenticated, userController.disable2fa);
router.post('/api/password', isAuthenticated, userController.changePassword);

module.exports = router;
