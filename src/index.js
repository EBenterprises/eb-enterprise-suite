const { scanPorts } = require('./scanner');
const { manageTabs } = require('./tabs');
const fs = require('fs');
const path = require('path');

async function main() {
    const config = JSON.parse(fs.readFileSync(path.join(__dirname, '../config/config.json'), 'utf8'));
    
    console.log('=== Starting Unified Automation Suite ===');
    
    console.time('Total Execution Time');
    const openPorts = await scanPorts(
        config.scanner.host,
        config.scanner.startPort,
        config.scanner.endPort,
        config.scanner.concurrency,
        config.scanner.timeout
    );

    await manageTabs();
    
    console.timeEnd('Total Execution Time');
    console.log(`=== Suite Execution Complete. Open Ports Found: ${openPorts.length} ===`);
}

main();
