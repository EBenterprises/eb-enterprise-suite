const { execSync } = require('child_process');
const https = require('https');

console.log("[+] Verifying GitHub token scopes and API access...");

const token = "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";

const options = {
    hostname: 'api.github.com',
    path: '/user',
    method: 'GET',
    headers: {
        'User-Agent': 'Node.js-App',
        'Authorization': `token ${token}`
    }
};

const req = https.request(options, (res) => {
    let data = '';
    res.on('data', (chunk) => { data += chunk; });
    res.on('end', () => {
        if (res.statusCode === 200) {
            const user = JSON.parse(data);
            console.log(`[+] Token is valid! Authenticated as GitHub user: ${user.login}`);
            console.log(`[+] Repo scopes may be missing or the token needs explicit permissions for organization 'EBenterprises'.`);
            console.log(`[+] Let's try pushing using HTTPS with explicit credential passing:`);
            try {
                execSync(`git push https://${token}@github.com/EBenterprises/sales-tracker.git main`, { stdio: 'inherit' });
                console.log("[+] Push successful via direct URL credentials!");
            } catch (err) {
                console.log("[-] Direct URL push failed. Ensure your PAT has the 'repo' scope and SSO authorization if required by EBenterprises.");
            }
        } else {
            console.log(`[-] Token authentication failed with status code ${res.statusCode}: ${data}`);
        }
    });
});

req.on('error', (e) => {
    console.log(`[-] Network error during token verification: ${e.message}`);
});

req.end();
