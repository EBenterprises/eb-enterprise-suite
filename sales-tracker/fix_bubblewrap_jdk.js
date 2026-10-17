const fs = require('fs');
const path = require('path');

// Bubblewrap expects JDK 17 specifically in its download path, but Termux has JDK 21 (`java -version` works).
// Let's create a symlink or point Bubblewrap to the system java path so it skips downloading and uses JDK 21!
const homeDir = process.env.HOME || '/data/data/com.termux/files/home';
const bubblewrapDir = path.join(homeDir, '.bubblewrap');
const jdkDir = path.join(bubblewrapDir, 'jdk');

if (!fs.existsSync(bubblewrapDir)) {
    fs.mkdirSync(bubblewrapDir, { recursive: true });
}

// Create a mock or link structure so bubblewrap thinks its downloaded JDK is present,
// or configure twa-manifest.json to bypass JDK download if possible.
console.log("[+] Java 21 is installed at system level. Configuring symlinks for Bubblewrap...");

const javaPath = '/data/data/com.termux/files/usr';
if (fs.existsSync(javaPath)) {
    if (!fs.existsSync(jdkDir)) {
        fs.symlinkSync(javaPath, jdkDir, 'junction');
        console.log("[+] Linked system Java to Bubblewrap JDK directory.");
    }
}
