const db = require('../config/database');
const bcrypt = require('bcryptjs');

const User = {
  create: async (username, email, password) => {
    const hashedPassword = await bcrypt.hash(password, 10);
    const data = { users: db.getUsers(), settings: db.getSettings() };
    
    const newId = data.users.length > 0 ? Math.max(...data.users.map(u => u.id)) + 1 : 1;
    const newUser = {
      id: newId,
      username,
      email,
      password: hashedPassword,
      created_at: new Date().toISOString()
    };
    
    data.users.push(newUser);

    const newSettings = {
      id: data.settings.length > 0 ? Math.max(...data.settings.map(s => s.id)) + 1 : 1,
      user_id: newId,
      theme: 'obsidian',
      email_notifications: 1,
      two_factor: 0,
      language: 'en'
    };

    data.settings.push(newSettings);
    db.save(data);

    return { id: newId, username, email };
  },

  findByEmail: (email) => {
    const users = db.getUsers();
    return users.find(u => u.email === email) || null;
  },

  findById: (id) => {
    const users = db.getUsers();
    const user = users.find(u => u.id === id);
    if (!user) return null;
    return { id: user.id, username: user.username, email: user.email, created_at: user.created_at };
  },

  verifyPassword: async (inputPassword, hashedPassword) => {
    return await bcrypt.compare(inputPassword, hashedPassword);
  }
};

module.exports = User;
