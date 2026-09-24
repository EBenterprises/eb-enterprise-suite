const fs = require('fs');
const path = require('path');

console.log('[EB-ENTERPRISES] Compiling Beyond Horizon Manifest...');

const distDir = path.join(__dirname, '../../dist');
if (!fs.existsSync(distDir)) {
  fs.mkdirSync(distDir, { recursive: true });
}

const horizonManifest = {
  organization: 'EBenterprises',
  managedBy: 'eastonbodeuxenterprises@gmail.com',
  version: '60.0.0',
  horizonAt: new Date().toISOString(),
  activeNodes: [
    { id: 'b-1', name: 'Titan-OS / ebOS Autonomous Core', status: 'SYNCHRONIZED' },
    { id: 'b-2', name: 'BuySideOnline® & Tap.eco Global Pipeline', status: 'SYNCHRONIZED' },
    { id: 'b-3', name: 'TapChat & P2P Board Games Mesh', status: 'SYNCHRONIZED' },
    { id: 'b-4', name: 'CoinScan & Eggfinder Optical Telemetry', status: 'SYNCHRONIZED' }
  ],
  status: 'HORIZON_UNLOCKED'
};

const manifestPath = path.join(distDir, 'horizon-manifest.json');
fs.writeFileSync(manifestPath, JSON.stringify(horizonManifest, null, 2));
console.log(`[SUCCESS] Beyond Horizon manifest compiled at: ${manifestPath}`);
