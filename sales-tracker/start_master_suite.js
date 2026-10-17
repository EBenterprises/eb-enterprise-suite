const { exec } = require('child_process');
const fs = require('fs');

console.log("[+] Starting Enterprise P2P Master Suite on designated ports...");

// Let's check if server.js exists and run it
if (fs.existsSync('server.js')) {
    const child = exec('node server.js', (err, stdout, stderr) => {
        if (err) console.error(`server.js error: ${err}`);
    });
    child.stdout.on('data', data => process.stdout.write(data));
    child.stderr.on('data', data => process.stderr.write(data));
} else {
    console.error("[-] server.js not found!");
}
