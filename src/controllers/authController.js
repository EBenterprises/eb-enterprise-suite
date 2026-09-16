const User = require('../models/User');
const Settings = require('../models/Settings');
const speakeasy = require('speakeasy');
const qrcode = require('qrcode');

const authController = {
  getLogin: (req, res) => {
    if (req.session.userId) return res.redirect('/dashboard');
    res.sendFile('login.html', { root: './src/views' });
  },

  postLogin: async (req, res) => {
    try {
      const { email, password, token } = req.body;
      const user = await User.findByEmail(email);
      
      if (!user || !(await User.verifyPassword(password, user.password))) {
        return res.status(401).json({ error: 'Invalid email or password' });
      }

      const settings = Settings.getByUserId(user.id);
      if (settings.two_factor === 1) {
        if (!token) {
          return res.status(200).json({ require2fa: true, email: user.email });
        }
        const verified = speakeasy.totp.verify({
          secret: settings.two_factor_secret,
          encoding: 'base32',
          token: token,
          window: 1
        });
        if (!verified) {
          return res.status(401).json({ error: 'Invalid 2FA authentication token' });
        }
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
