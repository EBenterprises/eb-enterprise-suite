const express = require('express');
const path = require('path');
const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

const profiles = [
  { id: 1, name: 'Aria Vance', age: 28, bio: 'Architect & espresso enthusiast. Looking for someone who appreciates clean code and midnight city walks.', image: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=600&auto=format&fit=crop&q=80' },
  { id: 2, name: 'Julian Cross', age: 31, bio: 'Systems engineer and backcountry splitboarder. Let’s talk algorithms or alpine routes.', image: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=600&auto=format&fit=crop&q=80' },
  { id: 3, name: 'Elena Rostova', age: 26, bio: 'UX designer crafting digital sanctuaries. Obsessed with minimalist aesthetics and vintage synths.', image: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=600&auto=format&fit=crop&q=80' }
];

app.get('/api/profiles', (req, res) => {
  res.json(profiles);
});

app.post('/api/match', (req, res) => {
  const { profileId, action } = req.body;
  console.log(`[Action] Profile ${profileId} received action: ${action}`);
  res.json({ success: true, match: action === 'like', message: action === 'like' ? 'It’s a Match!' : 'Passed' });
});

app.listen(PORT, () => {
  console.log(`[✓] PulseMatch server active on port ${PORT}`);
});
