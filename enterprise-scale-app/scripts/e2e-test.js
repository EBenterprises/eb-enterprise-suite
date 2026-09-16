const http = require('http');

const API_HOST = 'localhost';
const API_PORT = 5000;

function request(method, path, headers = {}, body = null) {
  return new Promise((resolve, reject) => {
    const data = body ? JSON.stringify(body) : null;
    const options = {
      hostname: API_HOST,
      port: API_PORT,
      path: path,
      method: method,
      headers: {
        'Content-Type': 'application/json',
        ...headers
      }
    };
    if (data) {
      options.headers['Content-Length'] = Buffer.byteLength(data);
    }

    const req = http.request(options, (res) => {
      let responseBody = '';
      res.on('data', (chunk) => responseBody += chunk);
      res.on('end', () => {
        try {
          const json = responseBody ? JSON.parse(responseBody) : {};
          resolve({ status: res.statusCode, headers: res.headers, body: json });
        } catch (e) {
          resolve({ status: res.statusCode, headers: res.headers, body: responseBody });
        }
      });
    });

    req.on('error', reject);
    if (data) req.write(data);
    req.end();
  });
}

async function runE2ETests() {
  console.log('[E2E Test] Starting End-to-End verification suite...');
  const testEmail = `operator_${Date.now()}@enterprise.local`;
  const testPassword = 'SecurePassword123!';

  // 1. Health Check
  const health = await request('GET', '/health');
  if (health.status !== 200 || health.body.status !== 'operational') {
    console.error('[E2E Test] Health check failed:', health);
    process.exit(1);
  }
  console.log('[E2E Test] ✓ Health check operational');

  // 2. Register Operator
  const register = await request('POST', '/api/auth/register', {}, { email: testEmail, password: testPassword });
  if (register.status !== 201 || !register.body.token) {
    console.error('[E2E Test] Registration failed:', register);
    process.exit(1);
  }
  console.log('[E2E Test] ✓ Operator successfully registered & token issued');
  const token = register.body.token;

  // 3. Create Item Payload
  const createItem = await request('POST', '/api/items', { 'Authorization': `Bearer ${token}` }, { name: 'Alpha Telemetry Node' });
  if (createItem.status !== 201 || !createItem.body.success) {
    console.error('[E2E Test] Item creation failed:', createItem);
    process.exit(1);
  }
  console.log('[E2E Test] ✓ Item injected successfully via secured endpoint');

  // 4. Fetch Items
  const fetchItems = await request('GET', '/api/items', { 'Authorization': `Bearer ${token}` });
  if (fetchItems.status !== 200 || !fetchItems.body.data || fetchItems.body.data.length === 0) {
    console.error('[E2E Test] Fetch items failed:', fetchItems);
    process.exit(1);
  }
  console.log(`[E2E Test] ✓ Fetched ${fetchItems.body.data.length} records securely`);

  console.log('[E2E Test] All verification suites passed successfully.');
}

runE2ETests().catch((err) => {
  console.error('[E2E Test] Critical test failure:', err);
  process.exit(1);
});
