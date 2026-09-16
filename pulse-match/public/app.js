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
