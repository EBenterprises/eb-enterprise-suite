const fs = require('fs');
const path = require('path');

console.log('[EB-ENTERPRISES] Compiling Showtime Production Manifest...');

const distDir = path.join(__dirname, '../../dist');
if (!fs.existsSync(distDir)) {
  fs.mkdirSync(distDir, { recursive: true });
}

const showManifest = {
  organization: 'EBenterprises',
  managedBy: 'eastonbodeuxenterprises@gmail.com',
  version: '40.0.0',
  launchedAt: new Date().toISOString(),
  productionFeeds: [
    { id: 'show-1', channel: 'Titan-OS / ebOS Live Stream', bitrate: '1080p60', status: 'BROADCASTING' },
    { id: 'show-2', channel: 'BuySideOnline® & Tap.eco Live Funnel', bitrate: 'Real-Time', status: 'BROADCASTING' },
    { id: 'show-3', channel: 'TapChat & P2P Board Games Feed', bitrate: 'Direct-Connect', status: 'BROADCASTING' },
    { id: 'show-4', channel: 'CoinScan & Eggfinder Radar', bitrate: 'GPS / Vision', status: 'BROADCASTING' }
  ],
  status: 'SHOWTIME_LIVE'
};

const manifestPath = path.join(distDir, 'show-manifest.json');
fs.writeFileSync(manifestPath, JSON.stringify(showManifest, null, 2));
console.log(`[SUCCESS] Showtime manifest compiled at: ${manifestPath}`);
