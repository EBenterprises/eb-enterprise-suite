const db = require('../config/database');

const Settings = {
  getByUserId: (userId) => {
    const settings = db.getSettings();
    return settings.find(s => s.user_id === userId) || {
      user_id: userId,
      theme: 'obsidian',
      email_notifications: 1,
      two_factor: 0,
      two_factor_secret: null,
      language: 'en',
      accent_color: '#00d2c4'
    };
  },

  updateByUserId: (userId, { theme, email_notifications, two_factor, language, accent_color }) => {
    const data = { users: db.getUsers(), settings: db.getSettings(), audit_logs: db.getAuditLogs() };
    let settingIndex = data.settings.findIndex(s => s.user_id === userId);

    const existing = settingIndex !== -1 ? data.settings[settingIndex] : {};

    const updatedSettings = {
      id: settingIndex !== -1 ? existing.id : (data.settings.length > 0 ? Math.max(...data.settings.map(s => s.id)) + 1 : 1),
      user_id: userId,
      theme: theme || existing.theme || 'obsidian',
      email_notifications: email_notifications !== undefined ? (email_notifications ? 1 : 0) : (existing.email_notifications ?? 1),
      two_factor: two_factor !== undefined ? (two_factor ? 1 : 0) : (existing.two_factor ?? 0),
      two_factor_secret: existing.two_factor_secret || null,
      two_factor_temp: existing.two_factor_temp || null,
      language: language || existing.language || 'en',
      accent_color: accent_color || existing.accent_color || '#00d2c4'
    };

    if (settingIndex !== -1) {
      data.settings[settingIndex] = updatedSettings;
    } else {
      data.settings.push(updatedSettings);
    }

    data.audit_logs.push({
      id: data.audit_logs.length + 1,
      user_id: userId,
      action: 'SETTINGS_UPDATED',
      ip: '127.0.0.1',
      timestamp: new Date().toISOString()
    });

    db.save(data);
    return { success: true };
  },

  setTempSecret: (userId, secret) => {
    const data = { users: db.getUsers(), settings: db.getSettings(), audit_logs: db.getAuditLogs() };
    let settingIndex = data.settings.findIndex(s => s.user_id === userId);
    if (settingIndex !== -1) {
      data.settings[settingIndex].two_factor_temp = secret;
      db.save(data);
    }
  },

  enable2FA: (userId, secret) => {
    const data = { users: db.getUsers(), settings: db.getSettings(), audit_logs: db.getAuditLogs() };
    let settingIndex = data.settings.findIndex(s => s.user_id === userId);
    if (settingIndex !== -1) {
      data.settings[settingIndex].two_factor = 1;
      data.settings[settingIndex].two_factor_secret = secret;
      data.settings[settingIndex].two_factor_temp = null;
      data.audit_logs.push({
        id: data.audit_logs.length + 1,
        user_id: userId,
        action: '2FA_ENABLED',
        ip: '127.0.0.1',
        timestamp: new Date().toISOString()
      });
      db.save(data);
    }
  },

  disable2FA: (userId) => {
    const data = { users: db.getUsers(), settings: db.getSettings(), audit_logs: db.getAuditLogs() };
    let settingIndex = data.settings.findIndex(s => s.user_id === userId);
    if (settingIndex !== -1) {
      data.settings[settingIndex].two_factor = 0;
      data.settings[settingIndex].two_factor_secret = null;
      data.settings[settingIndex].two_factor_temp = null;
      data.audit_logs.push({
        id: data.audit_logs.length + 1,
        user_id: userId,
        action: '2FA_DISABLED',
        ip: '127.0.0.1',
        timestamp: new Date().toISOString()
      });
      db.save(data);
    }
  }
};

module.exports = Settings;
