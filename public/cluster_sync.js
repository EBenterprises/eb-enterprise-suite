// Dynamic Real-Time Mesh Synchronization via Server-Sent Events (SSE) & Live Geo-Tracking
let liveEventSource = null;

function initLiveMeshStream() {
    if (liveEventSource) liveEventSource.close();
    
    liveEventSource = new EventSource('/api/stream');
    
    liveEventSource.onmessage = (event) => {
        try {
            const data = JSON.parse(event.data);
            if (data.type === 'STOCK_UPDATE') {
                updateFarmStockUI(data.farmId, data.stock);
                showToast(`⚡ Live Mesh Sync: Farm #${data.farmId} stock updated to ${data.stock} doz`);
            } else if (data.type === 'FARM_ADDED') {
                showToast(`🌾 New Producer Node Added: ${data.farm.name}`);
                loadFarms();
            }
        } catch (e) {
            console.error('Failed to parse SSE message', e);
        }
    };

    liveEventSource.onerror = () => {
        console.warn('[MESH] SSE connection interrupted. Reconnecting in 3s...');
        setTimeout(initLiveMeshStream, 3000);
    };
}

function updateFarmStockUI(farmId, stock) {
    const stockEl = document.getElementById(`stock_${farmId}`);
    const btnEl = document.getElementById(`btn_${farmId}`);
    if (stockEl) {
        stockEl.textContent = `${stock} dozen available`;
        stockEl.className = `stock-badge ${stock <= 5 ? 'low' : ''}`;
    }
    if (btnEl) {
        if (stock <= 0) {
            btnEl.disabled = true;
            btnEl.textContent = 'Sold Out';
        } else {
            btnEl.disabled = false;
            btnEl.textContent = '🔒 Instant Reserve & Pay';
        }
    }
}

// Automatically initialize live sync on load
window.addEventListener('DOMContentLoaded', () => {
    initLiveMeshStream();
});
