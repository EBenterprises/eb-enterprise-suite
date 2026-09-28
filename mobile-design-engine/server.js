const express = require('express');
const cors = require('cors');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// Raw unrestricted token compilation endpoint
app.post('/api/compile', (req, res) => {
  const { cssVariables, rawHtml } = req.body;
  res.json({ success: true, compiledAt: new Date().toISOString() });
});

app.listen(PORT, () => {
  console.log(`⚡ Unrestricted Design Engine running at http://localhost:${PORT}`);
});
