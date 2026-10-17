const { execSync } = require('child_process');
const fs = require('fs');

console.log("[+] Installing OpenJDK 17 and dependencies for Termux/Linux...");
try {
    execSync('pkg update -y && pkg install openjdk-17 wget curl -y', { stdio: 'inherit' });
    console.log("[+] JDK 17 installed successfully!");
} catch (e) {
    console.log("[-] Automatic pkg install failed or not on Termux. Please ensure Java JDK 17 is installed.");
}
