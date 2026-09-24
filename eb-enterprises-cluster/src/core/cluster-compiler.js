const fs = require('fs');
const path = require('path');

console.log('[EB-ENTERPRISES] Compiling Cluster Ecosystem Manifest...');

const distDir = path.join(__dirname, '../../dist');
if (!fs.existsSync(distDir)) {
  fs.mkdirSync(distDir, { recursive: true });
}

const clusterManifest = {
  organization: 'EBenterprises',
  managedBy: 'eastonbodeuxenterprises@gmail.com',
  version: '20.0.0',
  clusteredAt: new Date().toISOString(),
  workers: [
    { id: 'worker-1', role: 'Titan-OS / ebOS Kernel Core', port: 8801 },
    { id: 'worker-2', role: 'BuySideOnline® & Nexus Ledger', port: 8802 },
    { id: 'worker-3', role: 'TapChat & Secure Vault Auth', port: 8803 }
  ],
  status: 'CLUSTER_READY'
};

const manifestPath = path.join(distDir, 'cluster-manifest.json');
fs.writeFileSync(manifestPath, JSON.stringify(clusterManifest, null, 2));
console.log(`[SUCCESS] Cluster manifest generated at: ${manifestPath}`);
