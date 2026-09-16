const db = require('../config/database');

const Settings = {
  getByUserId: (userId) => {
    const settings = db.getSettings();
    return settings.find(s => s.user_id === userId) || {
      user_id: userId,
      theme: 'obsidian',
      email_notifications: 1,
      two_factor: 0,
      language: 'en'
    };
  },

  updateByUserId: (userId, { theme, email_notifications, two_factor, language }) => {
    const data = { users: db.getUsers(), settings: db.getSettings() };
    let settingIndex = data.settings.findIndex(s => s.user_id === userId);

    const updatedSettings = {
      id: settingIndex !== -1 ? data.settings[settingIndex].id : (data.settings.length > 0 ? Math.max(...data.settings.map(s => s.id)) + 1 : 1),
      user_id: userId,
      theme: theme || 'obsidian',
      email_notifications: email_notifications ? 1 : 0,
      two_factor: two_factor ? 1 : 0,
      language: language || 'en'
    };

    if (settingIndex !== -1) {
      data.settings[settingIndex] = updatedSettings;
    } else {
      data.settings.push(updatedSettings);
    }

    db.save(data);
    return { success: true };
  }
};

module.exports = Settings;
