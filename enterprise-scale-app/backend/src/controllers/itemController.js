const db = require('../config/db');

exports.getItems = async (req, res, next) => {
  try {
    const result = await db.query('SELECT * FROM items WHERE user_id = $1 ORDER BY id DESC', [req.user.id]);
    res.json({ success: true, data: result.rows });
  } catch (err) {
    next(err);
  }
};

exports.createItem = async (req, res, next) => {
  try {
    const { name, metadata } = req.body;
    if (!name) {
      return res.status(400).json({ success: false, error: 'Item name is required' });
    }

    const newItem = await db.query(
      'INSERT INTO items (name, user_id, metadata) VALUES ($1, $2, $3) RETURNING *',
      [name, req.user.id, metadata || {}]
    );
    res.status(201).json({ success: true, data: newItem.rows[0] });
  } catch (err) {
    next(err);
  }
};
