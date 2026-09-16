const express = require('express');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// Zero-Dependency JSON File Storage Setup
const dataDir = path.join(__dirname, 'data');
const dbPath = path.join(dataDir, 'leads.json');

if (!fs.existsSync(dataDir)) {
  fs.mkdirSync(dataDir, { recursive: true });
}

if (!fs.existsSync(dbPath)) {
  fs.writeFileSync(dbPath, JSON.stringify([], null, 2));
}

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, '../public')));

// API Endpoint for Lead Capture
app.post('/api/capture', (req, res) => {
  const { name, email } = req.body;
  
  if (!email || !email.includes('@')) {
    return res.status(400).json({ success: false, message: 'A valid email address is required.' });
  }

  try {
    const fileData = fs.readFileSync(dbPath, 'utf8');
    const leads = JSON.parse(fileData);

    const existingLead = leads.find(l => l.email.toLowerCase() === email.toLowerCase());
    if (existingLead) {
      return res.status(409).json({ success: false, message: 'This email is already registered.' });
    }

    const newLead = {
      id: Date.now(),
      name: name || 'Executive Guest',
      email: email.trim(),
      created_at: new Date().toISOString()
    };

    leads.push(newLead);
    fs.writeFileSync(dbPath, JSON.stringify(leads, null, 2));

    return res.json({ success: true, message: 'Access granted. Welcome to the elite tier.' });
  } catch (err) {
    console.error('Storage error:', err);
    return res.status(500).json({ success: false, message: 'Internal server error.' });
  }
});

app.listen(PORT, () => {
  console.log(`Capture page active on port ${PORT}`);
});
