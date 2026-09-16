const express = require('express');
const path = require('path');

function createApp() {
  const app = express();

  app.use(express.json());
  app.use(express.static(path.join(__dirname, '../public')));

  app.get('/api/sales', (req, res) => {
    res.json({
      instance: process.env.PORT || 3000,
      status: 'active',
      timestamp: new Date().toISOString(),
      salesData: [
        { id: 1, item: 'Enterprise License', amount: 1200 },
        { id: 2, item: 'Support Add-on', amount: 350 }
      ]
    });
  });

  return app;
}

module.exports = createApp;
