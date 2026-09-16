#!/usr/bin/env bash
set -e

PROJECT_DIR="${HOME}/pulse-match"
echo "[+] Scaffolding PulseMatch dating application in ${PROJECT_DIR}..."

mkdir -p "${PROJECT_DIR}/public"
cd "${PROJECT_DIR}"

cat << 'JSON' > package.json
{
  "name": "pulse-match",
  "version": "1.0.0",
  "description": "Cross-device responsive full-stack dating app prototype",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.19.2"
  }
}
JSON

cat << 'JS' > server.js
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
JS

cat << 'HTML' > public/index.html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>PulseMatch | Executive Dating</title>
  <link rel="stylesheet" href="style.css">
</head>
<body>
  <div class="app-container">
    <header class="app-header">
      <h1>Pulse<span>Match</span></h1>
      <p>Curated Connections</p>
    </header>
    <main id="card-container" class="card-container">
      <div class="loading">Initializing secure connection...</div>
    </main>
    <footer class="action-bar" id="action-bar" style="display: none;">
      <button id="pass-btn" class="btn btn-pass">✕</button>
      <button id="like-btn" class="btn btn-like">♥</button>
    </footer>
  </div>
  <script src="app.js"></script>
</body>
</html>
HTML

cat << 'CSS' > public/style.css
:root {
  --bg-obsidian: #0B0F12;
  --card-bg: #131A21;
  --accent-teal: #14B8A6;
  --accent-teal-glow: rgba(20, 184, 166, 0.2);
  --highlight-gold: #D4AF37;
  --text-main: #F3F4F6;
  --text-muted: #9CA3AF;
  --danger: #EF4444;
}
* {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
}
body {
  background-color: var(--bg-obsidian);
  color: var(--text-main);
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 100vh;
  overflow: hidden;
}
.app-container {
  width: 100%;
  max-width: 400px;
  height: 100vh;
  max-height: 800px;
  background-color: var(--card-bg);
  border-radius: 20px;
  border: 1px solid rgba(212, 175, 55, 0.2);
  display: flex;
  flex-direction: column;
  box-shadow: 0 20px 40px rgba(0, 0, 0, 0.6);
  overflow: hidden;
}
.app-header {
  padding: 20px;
  text-align: center;
  border-bottom: 1px solid rgba(255, 255, 255, 0.05);
}
.app-header h1 {
  font-size: 1.5rem;
  letter-spacing: 1px;
  color: var(--text-main);
}
.app-header h1 span {
  color: var(--highlight-gold);
}
.app-header p {
  font-size: 0.75rem;
  color: var(--text-muted);
  text-transform: uppercase;
  letter-spacing: 2px;
  margin-top: 4px;
}
.card-container {
  flex: 1;
  position: relative;
  padding: 20px;
  display: flex;
  justify-content: center;
  align-items: center;
}
.profile-card {
  position: absolute;
  width: calc(100% - 40px);
  height: calc(100% - 40px);
  background: var(--bg-obsidian);
  border-radius: 16px;
  overflow: hidden;
  border: 1px solid rgba(20, 184, 166, 0.3);
  box-shadow: 0 10px 25px rgba(0,0,0,0.5);
  display: flex;
  flex-direction: column;
}
.profile-image {
  width: 100%;
  height: 65%;
  object-fit: cover;
}
.profile-info {
  padding: 20px;
  flex: 1;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
}
.profile-info h2 {
  font-size: 1.4rem;
  color: var(--text-main);
  margin-bottom: 6px;
}
.profile-info h2 span {
  font-weight: 300;
  color: var(--highlight-gold);
}
.profile-info p {
  font-size: 0.9rem;
  color: var(--text-muted);
  line-height: 1.4;
}
.action-bar {
  padding: 20px;
  display: flex;
  justify-content: space-around;
  align-items: center;
  border-top: 1px solid rgba(255, 255, 255, 0.05);
}
.btn {
  width: 60px;
  height: 60px;
  border-radius: 50%;
  border: none;
  font-size: 1.5rem;
  cursor: pointer;
  display: flex;
  justify-content: center;
  align-items: center;
  transition: transform 0.2s, box-shadow 0.2s;
}
.btn:active {
  transform: scale(0.92);
}
.btn-pass {
  background: var(--bg-obsidian);
  color: var(--danger);
  border: 2px solid var(--danger);
}
.btn-like {
  background: var(--bg-obsidian);
  color: var(--accent-teal);
  border: 2px solid var(--accent-teal);
  box-shadow: 0 0 15px var(--accent-teal-glow);
}
.match-overlay {
  position: absolute;
  top: 0; left: 0; width: 100%; height: 100%;
  background: rgba(11, 15, 18, 0.9);
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  z-index: 10;
  text-align: center;
  padding: 20px;
}
.match-overlay h2 {
  font-size: 2.5rem;
  color: var(--highlight-gold);
  margin-bottom: 10px;
}
.match-overlay p {
  color: var(--text-muted);
}
CSS

cat << 'JS' > public/app.js
let profiles = [];
let currentIndex = 0;

const cardContainer = document.getElementById('card-container');
const actionBar = document.getElementById('action-bar');

async function fetchProfiles() {
  try {
    const res = await fetch('/api/profiles');
    profiles = await res.json();
    renderCard();
  } catch (err) {
    cardContainer.innerHTML = '<p class="text-muted">Failed to sync profile stream.</p>';
  }
}

function renderCard() {
  if (currentIndex >= profiles.length) {
    cardContainer.innerHTML = '<div class="text-center" style="color: var(--text-muted)">No more profiles available in your sector.</div>';
    actionBar.style.display = 'none';
    return;
  }

  const profile = profiles[currentIndex];
  cardContainer.innerHTML = `
    <div class="profile-card">
      <img src="${profile.image}" alt="${profile.name}" class="profile-image">
      <div class="profile-info">
        <div>
          <h2>${profile.name}, <span>${profile.age}</span></h2>
          <p>${profile.bio}</p>
        </div>
      </div>
    </div>
  `;
  actionBar.style.display = 'flex';
}

async function handleAction(action) {
  if (currentIndex >= profiles.length) return;
  const profile = profiles[currentIndex];

  try {
    const res = await fetch('/api/match', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ profileId: profile.id, action })
    });
    const data = await res.json();

    if (data.match) {
      showMatchPopup(profile);
    } else {
      nextCard();
    }
  } catch (err) {
    console.error('Transmission error:', err);
  }
}

function showMatchPopup(profile) {
  const popup = document.createElement('div');
  popup.className = 'match-overlay';
  popup.innerHTML = `
    <h2>It's a Match!</h2>
    <p>You and ${profile.name} have connected successfully.</p>
    <button class="btn btn-like" style="margin-top: 20px; width: auto; padding: 0 20px; font-size: 1rem;" onclick="this.parentElement.remove(); nextCard();">Continue</button>
  `;
  cardContainer.appendChild(popup);
}

window.nextCard = function() {
  currentIndex++;
  renderCard();
}

document.getElementById('pass-btn').addEventListener('click', () => handleAction('pass'));
document.getElementById('like-btn').addEventListener('click', () => handleAction('like'));

fetchProfiles();
JS

cat << 'DOCKER' > Dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --production
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
DOCKER

echo "[✓] PulseMatch files successfully generated in ${PROJECT_DIR}."
