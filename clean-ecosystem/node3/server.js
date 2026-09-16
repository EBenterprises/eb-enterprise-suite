const express = require('express'); const sqlite3 = require('sqlite3').verbose(); const path = require('path'); const cors = require('cors');
const app = express(); app.use(express.urlencoded({ extended: true })); app.use(cors());
const db = new sqlite3.Database(path.join(__dirname, '../database_bookings.db'));
db.run(`CREATE TABLE IF NOT EXISTS bookings (id INTEGER PRIMARY KEY AUTOINCREMENT, client_name TEXT, booking_date TEXT, booking_time TEXT)`);
app.post('/book', (req, res) => {
    db.run(`INSERT INTO bookings (client_name, booking_date, booking_time) VALUES (?, ?, ?)`, [req.body.client_name, req.body.booking_date, req.body.booking_time], () => {
        res.redirect('http://localhost:3004/node4/');
    });
});
app.listen(3003, () => console.log('[Node 3] Active on port 3003'));
