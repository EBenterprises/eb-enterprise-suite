// SnapMap x EggFinder® Spatial Radar & Live Mesh Engine
// Recreates the immersive dark-mode tactical map aesthetic of SnapMap with real-time farm-fresh egg telemetry.

let snapMapState = {
    farms: [],
    selectedFarm: null,
    radarAngle: 0,
    mapCenter: { x: 50, y: 50 } // percentage coordinates on tactical grid
};

async function initSnapMap() {
    const container = document.getElementById('snapMapCanvas');
    if (!container) return;

    try {
        const res = await fetch('/api/farms');
        snapMapState.farms = await res.json();
        renderSnapMapPins();
    } catch (e) {
        console.error('Failed to load SnapMap farm telemetry', e);
    }
}

function renderSnapMapPins() {
    const container = document.getElementById('snapMapPinsContainer');
    if (!container) return;

    // Map geographic coordinates to visual layout percentages for the tactical radar
    container.innerHTML = snapMapState.farms.map((farm, index) => {
        // Generate stable pseudo-random map positions based on farm ID if lat/lng are fixed
        const posX = 20 + (index * 18) % 65;
        const posY = 25 + (index * 22) % 55;
        const isLow = farm.stock <= 5;

        return `
            <div class="snap-pin-wrapper" style="left: ${posX}%; top: ${posY}%;" onclick="selectSnapFarm(${farm.id})">
                <div class="snap-avatar-ring ${isLow ? 'low-stock' : ''}">
                    <img src="${farm.image || 'https://images.unsplash.com/photo-1516467508483-a7212febe31a?w=200&auto=format&fit=crop&q=80'}" alt="${farm.name}">
                </div>
                <div class="snap-pin-badge">
                    <span class="pin-name">${farm.name.split(' ')[0]}</span>
                    <span class="pin-stock ${isLow ? 'danger' : ''}">🥚 ${farm.stock}dz</span>
                </div>
                <div class="radar-pulse"></div>
            </div>
        `;
    }).join('');
}

function selectSnapFarm(farmId) {
    const farm = snapMapState.farms.find(f => f.id === farmId);
    if (!farm) return;
    snapMapState.selectedFarm = farm;

    const drawer = document.getElementById('snapDrawer');
    if (drawer) {
        drawer.classList.add('open');
        document.getElementById('drawerTitle').textContent = farm.name;
        document.getElementById('drawerDesc').textContent = farm.description || 'Certified organic free-range heritage eggs.';
        document.getElementById('drawerStock').textContent = `${farm.stock} dozen available`;
        document.getElementById('drawerPrice').textContent = `$${Number(farm.price || 7.50).toFixed(2)} /dz`;
        
        const buyBtn = document.getElementById('drawerBuyBtn');
        if (farm.stock <= 0) {
            buyBtn.disabled = true;
            buyBtn.textContent = 'Sold Out';
        } else {
            buyBtn.disabled = false;
            buyBtn.textContent = `🔒 Instant Reserve & Pay $${Number(farm.price || 7.50).toFixed(2)}`;
            buyBtn.onclick = () => openCheckoutModal(farm.id, farm.name, farm.price || 7.50, farm.stock);
        }
    }
}

function closeSnapDrawer() {
    const drawer = document.getElementById('snapDrawer');
    if (drawer) drawer.classList.remove('open');
}

window.addEventListener('DOMContentLoaded', () => {
    initSnapMap();
    setInterval(initSnapMap, 8000); // Live sync refresh
});
