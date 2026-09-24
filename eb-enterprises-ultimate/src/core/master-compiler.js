const fs = require('fs');
const path = require('path');

console.log('[EB-ENTERPRISES] Compiling Ultimate Enterprise Master Manifest...');

const distDir = path.join(__dirname, '../../dist');
if (!fs.existsSync(distDir)) {
  fs.mkdirSync(distDir, { recursive: true });
}

const masterManifest = {
  organization: 'EBenterprises',
  managedBy: 'eastonbodeuxenterprises@gmail.com',
  version: '25.0.0',
  compiledAt: new Date().toISOString(),
  ecosystem: [
    { name: 'Titan-OS / ebOS Kernel', status: 'ACTIVE', port: 9501 },
    { name: 'BuySideOnline® & Nexus', status: 'ACTIVE', port: 9502 },
    { name: 'TapChat & Secure Vault', status: 'ACTIVE', port: 9503 },
    { name: 'CoinScan & Eggfinder', status: 'ACTIVE', port: 9504 }
  ],
  status: 'ULTIMATE_ORCHESTRATION_READY'
};

const manifestPath = path.join(distDir, 'master-manifest.json');
fs.writeFileSync(manifestPath, JSON.stringify(masterManifest, null, 2));
console.log(`[SUCCESS] Master manifest compiled at: ${manifestPath}`);
