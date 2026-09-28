const { execSync } = require('child_process');

console.log('[EB Enterprises] Initializing live deployment trigger...');
try {
    console.log('[1/2] Verifying system dependencies...');
    execSync('npm install', { stdio: 'inherit' });
    console.log('[2/2] Triggering live server startup...');
    execSync('node src/server.js', { stdio: 'inherit' });
} catch (error) {
    console.error('[Deployment Error]', error.message);
    process.exit(1);
}
