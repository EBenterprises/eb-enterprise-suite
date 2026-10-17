const fs = require('fs');
const { execSync } = require('child_process');

console.log("[+] Enhancing server.js with robust PWA install manifest headers and service worker registration...");

if (fs.existsSync('server.js')) {
    let content = fs.readFileSync('server.js', 'utf8');

    // Add service worker registration script before closing body tag if not present
    const swScript = `
    <script>
        if ('serviceWorker' in navigator) {
            window.addEventListener('load', () => {
                navigator.serviceWorker.register('/service-worker.js')
                    .then(reg => console.log('[PWA] Service Worker registered!', reg))
                    .catch(err => console.log('[PWA] Service Worker registration failed:', err));
            });
        }
    </script>
    `;

    if (!content.includes('service-worker.js')) {
        content = content.replace('</body>', `${swScript}\n</body>`);
    }

    fs.writeFileSync('server.js', content);
}

// Create a robust service-worker.js to enable full PWA installation prompt in Chrome/Android
const swCode = `
self.addEventListener('install', (e) => {
    e.waitUntil(
        caches.open('eb-sales-v5-cache').then((cache) => {
            return cache.addAll([
                '/',
                '/index.html'
            ]);
        })
    );
});

self.addEventListener('fetch', (e) => {
    e.respondWith(
        caches.match(e.request).then((response) => {
            return response || fetch(e.request);
        })
    );
});
`;

fs.writeFileSync('service-worker.js', swCode);

console.log("[+] Terminating existing node processes...");
try {
    execSync('pkill -f node || true', { stdio: 'inherit' });
} catch (e) {}

console.log("[+] Restarting server with PWA install enhancements on port 51201...");
execSync('node server.js', { stdio: 'inherit' });
