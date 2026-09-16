const express = require('express');
const http = require('http');
const path = require('path');
const sqlite3 = require('sqlite3').verbose();

const PORT = process.env.PORT || 3000;
const app = express();
const server = http.createServer(app);

// Initialize SQLite database
const dbPath = path.join(__dirname, 'data', `sales_${PORT}.db`);
const db = new sqlite3.Database(dbPath, (err) => {
  if (err) console.error('Database connection error:', err.message);
  else console.log(`Connected to SQLite database on port ${PORT}`);
});

db.run(`CREATE TABLE IF NOT EXISTS sales (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  item TEXT NOT NULL,
  amount REAL NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
)`);

app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// API Endpoints
app.get('/api/sales', (req, res) => {
  db.all("SELECT * FROM sales ORDER BY id DESC", [], (err, rows) => {
    if (err) {
      res.status(500).json({ error: err.message });
      return;
    }
    res.json({
      instance: PORT,
      status: 'active',
      timestamp: new Date().toISOString(),
      salesData: rows.length > 0 ? rows : [
        { id: 1, item: 'Enterprise License', amount: 1200 },
        { id: 2, item: 'Support Add-on', amount: 350 }
      ]
    });
  });
});

app.post('/api/sales', (req, res) => {
  const { item, amount } = req.body;
  if (!item || !amount) {
    return res.status(400).json({ error: 'Item and amount are required' });
  }
  db.run("INSERT INTO sales (item, amount) VALUES (?, ?)", [item, amount], function(err) {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    res.json({ id: this.lastID, item, amount });
  });
});

server.listen(PORT, () => {
  console.log(`-> Deployed sales-tracker instance on port ${PORT} (PID: ${process.pid})`);
});
