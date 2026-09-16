// Complete Dynamic Reactive Engine for EggFinder® Executive Mesh
// Powers dynamic farm rendering, real-time geolocation filtering, instant cart management, and live telemetry.

let appState = {
    farms: [],
    searchQuery: '',
    maxDistance: 100, // km
    userLat: 49.8820,  // Default West Kelowna center
    userLng: -119.5900,
    selectedFarm: null,
    telemetryNodes: 5,
    activeTab: 'explore'
};

// Calculate haversine distance in km
function calculateDistance(lat1, lon1, lat2, lon2) {
    const R = 6371; // Radius of the earth in km
    const dLat = (lat2 - lat1) * (Math.PI / 180);
    const dLon = (lon2 - lon1) * (Math.PI / 180);
    const a = 
        Math.sin(dLat/2) * Math.sin(dLat/2) +
        Math.cos(lat1 * (Math.PI / 180)) * Math.cos(lat2 * (Math.PI / 180)) * 
        Math.sin(dLon/2) * Math.sin(dLon/2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
    return R * c;
}

async function fetchDynamicFarms() {
    try {
        const res = await fetch('/api/farms');
        const data = await res.json();
        appState.farms = data;
        renderDynamicFarms();
        updateTelemetryStats();
    } catch (e) {
        console.error('Failed to fetch dynamic farm data', e);
    }
}

function renderDynamicFarms() {
    const grid = document.getElementById('farmsGrid');
    if (!grid) return;

    const filtered = appState.farms.filter(farm => {
        const matchesQuery = farm.name.toLowerCase().includes(appState.searchQuery.toLowerCase()) ||
                             (farm.description && farm.description.toLowerCase().includes(appState.searchQuery.toLowerCase()));
        const dist = calculateDistance(appState.userLat, appState.userLng, farm.lat, farm.lng);
        return matchesQuery && dist <= appState.maxDistance;
    });

    if (filtered.length === 0) {
        grid.innerHTML = \`
            <div style="grid-column: 1 / -1; text-align: center; padding: 60px; background: var(--surface-panel); border: 1px dashed var(--border-subtle); border-radius: var(--radius-lg);">
                <h3 style="color: var(--text-main); font-size: 1.2rem; margin-bottom: 8px;">No active producer nodes match your filter criteria.</h3>
                <p style="color: var(--text-dim); font-size: 0.9rem;">Try expanding your distance radius or search query.</p>
            </div>
        \`;
        return;
    }

    grid.innerHTML = filtered.map(farm => {
        const dist = calculateDistance(appState.userLat, appState.userLng, farm.lat, farm.lng).toFixed(1);
        const isLowStock = farm.stock <= 5;
        
        return \`
            <div class="card" id="farm_card_\${farm.id}">
                <img src="\${farm.image || 'https://images.unsplash.com/photo-1516467508483-a7212febe31a?w=600&auto=format&fit=crop&q=80'}" class="card-img" alt="\${farm.name}">
                <div class="card-body">
                    <div>
                        <div style="display: flex; justify-content: space-between; align-items: start; margin-bottom: 6px;">
                            <h3 class="farm-title">\${farm.name}</h3>
                            <span style="font-size: 0.75rem; background: rgba(0,255,234,0.08); color: var(--accent-teal); padding: 4px 8px; border-radius: 6px; font-weight: 700; border: 1px solid var(--border-subtle);">\${dist} km away</span>
                        </div>
                        <p class="farm-desc">\${farm.description || 'Certified organic farm-fresh free-range eggs harvested daily.'}</p>
                    </div>
                    
                    <div>
                        <div class="meta-row">
                            <span class="stock-badge \${isLowStock ? 'low' : ''}" id="stock_\${farm.id}">
                                🥚 \${farm.stock} dozen available
                            </span>
                            <span class="price-tag">$\${Number(farm.price || 7.50).toFixed(2)} /dz</span>
                        </div>
                        
                        <button class="reserve-btn" id="btn_\${farm.id}" \${farm.stock <= 0 ? 'disabled' : ''} onclick="openCheckoutModal(\${farm.id}, '\${farm.name.replace(/'/g, "\\\\'")}', \${farm.price || 7.50}, \${farm.stock})">
                            \${farm.stock <= 0 ? 'Sold Out' : '🔒 Instant Reserve & Pay'}
                        </button>
                    </div>
                </div>
            </div>
        \`;
    }).join('');
}

function updateTelemetryStats() {
    const totalStock = appState.farms.reduce((acc, f) => acc + f.stock, 0);
    const activeNodesEl = document.getElementById('telemetryNodesCount');
    const totalStockEl = document.getElementById('telemetryTotalStock');
    if (activeNodesEl) activeNodesEl.textContent = `${appState.farms.length} Edge Nodes`;
    if (totalStockEl) totalStockEl.textContent = `${totalStock} Doz Active`;
}

function setupDynamicControls() {
    const searchInput = document.getElementById('searchInput');
    if (searchInput) {
        searchInput.addEventListener('input', (e) => {
            appState.searchQuery = e.target.value;
            renderDynamicFarms();
        });
    }

    const distanceSlider = document.getElementById('distanceSlider');
    if (distanceSlider) {
        distanceSlider.addEventListener('input', (e) => {
            appState.maxDistance = Number(e.target.value);
            const distLabel = document.getElementById('distanceLabel');
            if (distLabel) distLabel.textContent = `${appState.maxDistance} km`;
            renderDynamicFarms();
        });
    }
}

// Hook into initial load
window.addEventListener('DOMContentLoaded', () => {
    fetchDynamicFarms();
    setupDynamicControls();
    
    // Periodically poll for dynamic synchronization backup
    setInterval(fetchDynamicFarms, 10000);
});
