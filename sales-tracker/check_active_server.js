const http = require('http');

http.get('http://127.0.0.1:51201', (res) => {
    console.log(`[+] Server response status: ${res.statusCode}`);
    let data = '';
    res.on('data', chunk => data += chunk);
    res.on('end', () => {
        if (data.includes('Sales') || data.includes('Tracker') || data.includes('Preset')) {
            console.log("[+] Confirmed: Correct 'EB Sales & Payments Tracker' server is running on port 51201!");
        } else {
            console.log("[+] Server is responding, but page content looks different. Let's inspect server.js routing.");
        }
    });
}).on('error', (err) => {
    console.log(`[-] Server is not responding on port 51201: ${err.message}`);
});
