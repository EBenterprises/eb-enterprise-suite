const fs = require('fs');
const path = require('path');

console.log("[+] Packaging Sales Tracker as an offline/online Progressive Web App (PWA)...");

// 1. Create manifest.json
const manifest = {
  "name": "EB Sales & Payments Tracker",
  "short_name": "SalesTracker",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#0b0f19",
  "theme_color": "#0b0f19",
  "icons": [
    {
      "src": "/icon.png",
      "sizes": "192x192",
      "type": "image/png"
    }
  ]
};
fs.writeFileSync('manifest.json', JSON.stringify(manifest, null, 2));

// 2. Create service-worker.js for offline caching and background persistence
const serviceWorker = `
const CACHE_NAME = 'sales-tracker-v1';
const ASSETS = [
  '/',
  '/manifest.json'
];

self.addEventListener('install', (e) => {
  e.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll(ASSETS);
    })
  );
  self.skipWaiting();
});

self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys().then((keys) => {
      return Promise.all(
        keys.map((key) => {
          if (key !== CACHE_NAME) {
            return caches.delete(key);
          }
        })
      );
    })
  );
  self.claim();
});

self.addEventListener('fetch', (e) => {
  e.respondWith(
    fetch(e.request).catch(() => {
      return caches.match(e.request);
    })
  );
});
`;
fs.writeFileSync('service-worker.js', serviceWorker.trim());

// 3. Update server.js to serve manifest.json, service-worker.js, and inject PWA registration headers into HTML
let serverCode = fs.readFileSync('server.js', 'utf8');

// Inject service worker registration & manifest link into the HTML head section if not already present
const pwaHeaders = `
<link rel="manifest" href="/manifest.json">
<meta name="theme-color" content="#0b0f19">
<script>
  if ('serviceWorker' in navigator) {
    window.addEventListener('load', () => {
      navigator.serviceWorker.register('/service-worker.js')
        .then(reg => console.log('ServiceWorker registered:', reg.scope))
        .catch(err => console.error('ServiceWorker registration failed:', err));
    });
  }
</script>
`;

if (!serverCode.includes('manifest.json')) {
    // Insert before </head>
    serverCode = serverCode.replace('</head>', pwaHeaders + '\n</head>');
}

// Add routes in server.js to serve manifest.json and service-worker.js if not already present
const staticRoutes = `
app.get('/manifest.json', (req, res) => res.sendFile(path.join(__dirname, 'manifest.json')));
app.get('/service-worker.js', (req, res) => res.sendFile(path.join(__dirname, 'service-worker.js')));
`;

if (!serverCode.includes('/manifest.json')) {
    serverCode = serverCode.replace("const app = express();", "const app = express();\n" + staticRoutes);
}

fs.writeFileSync('server.js', serverCode);
console.log("[+] PWA packaging complete! Manifest and Service Worker integrated.");
