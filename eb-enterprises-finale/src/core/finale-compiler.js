const fs = require('fs');
const path = require('path');

console.log('[EB-ENTERPRISES] Compiling Grand Finale Manifest...');

const distDir = path.join(__dirname, '../../dist');
if (!fs.existsSync(distDir)) {
  fs.mkdirSync(distDir, { recursive: true });
}

const finaleManifest = {
  organization: 'EBenterprises',
  managedBy: 'eastonbodeuxenterprises@gmail.com',
  version: '50.0.0',
  finaleAt: new Date().toISOString(),
  activeBroadcasts: [
    { id: 'fin-1', name: 'Titan-OS / ebOS Kernel Live Broadcast', status: 'ON_AIR' },
    { id: 'fin-2', name: 'BuySideOnline® & Nexus Global Ticker', status: 'ON_AIR' },
    { id: 'fin-3', name: 'TapChat P2P WebRTC Direct Stage', status: 'ON_AIR' },
    { id: 'fin-4', name: 'CoinScan, Eggfinder & All Ecosystem Modules', status: 'ON_AIR' }
  ],
  status: 'GRAND_FINALE_RUNNING'
};

const manifestPath = path.join(distDir, 'finale-manifest.json');
fs.writeFileSync(manifestPath, JSON.stringify(finaleManifest, null, 2));
console.log(`[SUCCESS] Grand Finale manifest compiled at: ${manifestPath}`);
