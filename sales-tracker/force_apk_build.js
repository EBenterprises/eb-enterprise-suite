const { execSync } = require('child_process');
const fs = require('fs');

console.log("[+] Setting up JDK environment variables for Bubblewrap...");

const javaHome = '/data/data/com.termux/files/usr';
process.env.JAVA_HOME = javaHome;
process.env.PATH = `${javaHome}/bin:${process.env.PATH}`;

try {
    console.log("[+] Testing Java execution...");
    console.log(execSync('java -version 2>&1', { encoding: 'utf8' }));
    
    // Run bubblewrap build with "No" to prevent it from trying to download an incompatible JDK
    console.log("[+] Running Bubblewrap build with system JDK...");
    execSync('echo "No" | bubblewrap build', { stdio: 'inherit' });
} catch (e) {
    console.log("[-] Build encountered an issue. Let's inspect directory state.");
}
