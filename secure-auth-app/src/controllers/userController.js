const User = require('../models/User');
const Settings = require('../models/Settings');

const userController = {
  getDashboard: (req, res) => {
    res.sendFile('dashboard.html', { root: './src/views' });
  },

  getSettings: (req, res) => {
    res.sendFile('settings.html', { root: './src/views' });
  },

  getProfileData: async (req, res) => {
    try {
      const user = await User.findById(req.session.userId);
      const settings = await Settings.getByUserId(req.session.userId);
      res.json({ user, settings });
    } catch (err) {
      res.status(500).json({ error: 'Failed to retrieve profile data' });
    }
  },

  updateSettings: async (req, res) => {
    try {
      const { theme, email_notifications, two_factor, language } = req.body;
      await Settings.updateByUserId(req.session.userId, {
        theme,
        email_notifications,
        two_factor,
        language
      });
      res.json({ success: true, message: 'Settings updated successfully' });
    } catch (err) {
      res.status(500).json({ error: 'Failed to update settings' });
    }
  }
};

module.exports = userController;
