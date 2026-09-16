const User = require('../models/User');
const Settings = require('../models/Settings');
const db = require('../config/database');
const speakeasy = require('speakeasy');
const qrcode = require('qrcode');

const userController = {
  getDashboard: (req, res) => {
    res.sendFile('dashboard.html', { root: './src/views' });
  },

  getSettings: (req, res) => {
    res.sendFile('settings.html', { root: './src/views' });
  },

  getAnalytics: (req, res) => {
    res.sendFile('analytics.html', { root: './src/views' });
  },

  getProfileData: async (req, res) => {
    try {
      const user = await User.findById(req.session.userId);
      const settings = Settings.getByUserId(req.session.userId);
      const allLogs = db.getAuditLogs();
      const userLogs = allLogs.filter(l => l.user_id === req.session.userId).reverse().slice(0, 10);
      res.json({ user, settings, logs: userLogs });
    } catch (err) {
      res.status(500).json({ error: 'Failed to retrieve profile data' });
    }
  },

  updateSettings: async (req, res) => {
    try {
      const { theme, email_notifications, two_factor, language, accent_color } = req.body;
      Settings.updateByUserId(req.session.userId, {
        theme,
        email_notifications,
        two_factor,
        language,
        accent_color
      });
      res.json({ success: true, message: 'Settings updated successfully' });
    } catch (err) {
      res.status(500).json({ error: 'Failed to update settings' });
    }
  },

  setup2fa: async (req, res) => {
    try {
      const secret = speakeasy.generateSecret({ name: `Executive Spectrum (${req.session.userId})` });
      Settings.setTempSecret(req.session.userId, secret.base32);
      const qrDataUrl = await qrcode.toDataURL(secret.otpauth_url);
      res.json({ success: true, qr: qrDataUrl, secret: secret.base32 });
    } catch (err) {
      res.status(500).json({ error: 'Failed to generate 2FA secret' });
    }
  },

  verifyAndEnable2fa: (req, res) => {
    const { token } = req.body;
    const settings = Settings.getByUserId(req.session.userId);
    if (!settings.two_factor_temp) {
      return res.status(400).json({ error: 'No pending 2FA setup found' });
    }
    const verified = speakeasy.totp.verify({
      secret: settings.two_factor_temp,
      encoding: 'base32',
      token: token,
      window: 1
    });
    if (verified) {
      Settings.enable2FA(req.session.userId, settings.two_factor_temp);
      res.json({ success: true, message: 'Two-factor authentication enabled successfully' });
    } else {
      res.status(400).json({ error: 'Invalid verification token' });
    }
  },

  disable2fa: (req, res) => {
    Settings.disable2FA(req.session.userId);
    res.json({ success: true, message: 'Two-factor authentication disabled' });
  },

  changePassword: async (req, res) => {
    try {
      const { currentPassword, newPassword } = req.body;
      const data = db.getUsers();
      const user = data.find(u => u.id === req.session.userId);
      if (!user || !(await User.verifyPassword(currentPassword, user.password))) {
        return res.status(400).json({ error: 'Incorrect current password' });
      }
      await User.updatePassword(req.session.userId, newPassword);
      res.json({ success: true, message: 'Password updated successfully' });
    } catch (err) {
      res.status(500).json({ error: 'Failed to update password' });
    }
  }
};

module.exports = userController;
