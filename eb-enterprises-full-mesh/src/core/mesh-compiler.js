const fs = require('fs');
const path = require('path');

console.log('[EB-ENTERPRISES] Compiling Full Multi-Port Mesh Manifest...');

const distDir = path.join(__dirname, '../../dist');
if (!fs.existsSync(distDir)) {
  fs.mkdirSync(distDir, { recursive: true });
}

const meshManifest = {
  organization: 'EBenterprises',
  managedBy: 'eastonbodeuxenterprises@gmail.com',
  version: '200.0.0',
  compiledAt: new Date().toISOString(),
  nodes: [
    { name: 'Omniverse Master Command', port: 13000, type: 'Orchestrator' },
    { name: 'www.tap.eco', port: 13001, type: 'Affiliate & Community Platform' },
    { name: 'BuySideOnline® & Nexus', port: 13002, type: 'Payment Engine & Sales Tracker' },
    { name: 'Cuff P2P & TapChat', port: 13003, type: 'Consignment & Direct Board Games' },
    { name: 'Eggfinder & CoinScan', port: 13004, type: 'GPS Radar & Optical Coin ID' },
    { name: 'Titan-OS / ebOS Kernel', port: 13005, type: 'Low-Level Mobile OS & Compositor' }
  ],
  status: 'MESH_FULLY_INDEXED'
};

const manifestPath = path.join(distDir, 'mesh-manifest.json');
fs.writeFileSync(manifestPath, JSON.stringify(meshManifest, null, 2));
console.log(`[SUCCESS] Mesh manifest compiled at: ${manifestPath}`);
