const User = require('../models/User');

const authController = {
  getLogin: (req, res) => {
    if (req.session.userId) return res.redirect('/dashboard');
    res.sendFile('login.html', { root: './src/views' });
  },

  postLogin: async (req, res) => {
    try {
      const { email, password } = req.body;
      const user = await User.findByEmail(email);
      
      if (!user || !(await User.verifyPassword(password, user.password))) {
        return res.status(401).json({ error: 'Invalid email or password' });
      }

      req.session.userId = user.id;
      res.json({ success: true, redirect: '/dashboard' });
    } catch (err) {
      res.status(500).json({ error: 'Server error during login' });
    }
  },

  getRegister: (req, res) => {
    if (req.session.userId) return res.redirect('/dashboard');
    res.sendFile('register.html', { root: './src/views' });
  },

  postRegister: async (req, res) => {
    try {
      const { username, email, password } = req.body;
      if (!username || !email || !password) {
        return res.status(400).json({ error: 'All fields are required' });
      }

      const existing = await User.findByEmail(email);
      if (existing) {
        return res.status(400).json({ error: 'Email already registered' });
      }

      const user = await User.create(username, email, password);
      req.session.userId = user.id;
      res.json({ success: true, redirect: '/dashboard' });
    } catch (err) {
      res.status(500).json({ error: 'Server error during registration' });
    }
  },

  logout: (req, res) => {
    req.session.destroy(() => {
      res.redirect('/login');
    });
  }
};

module.exports = authController;
