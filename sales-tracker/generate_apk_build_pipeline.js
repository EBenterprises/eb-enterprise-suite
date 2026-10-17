const fs = require('fs');

console.log("[+] Generating complete and properly closed APK build pipeline script...");

const buildScript = `#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "[+] Initializing full native Android project layout..."
mkdir -p android_apk_project/app/src/main/java/com/ebenterprises/salestracker
mkdir -p android_apk_project/app/src/main/res/values

# 1. Write AndroidManifest.xml safely with properly closed heredoc
cat << 'EOM' > android_apk_project/app/src/main/AndroidManifest.xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.ebenterprises.salestracker">

    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

    <application
        android:allowBackup="true"
        android:label="EB Sales Tracker"
        android:usesCleartextTraffic="true"
        android:theme="@style/Theme.AppCompat.NoActionBar">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:configChanges="orientation|screenSize|keyboardHidden">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
EOM

# 2. Write MainActivity.java safely with properly closed heredoc
cat << 'EOM' > android_apk_project/app/src/main/java/com/ebenterprises/salestracker/MainActivity.java
package com.ebenterprises.salestracker;

import android.app.Activity;
import android.os.Bundle;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;

public class MainActivity extends Activity {
    private WebView webView;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        webView = new WebView(this);
        WebSettings webSettings = webView.getSettings();
        webSettings.setJavaScriptEnabled(true);
        webSettings.setDomStorageEnabled(true);
        webSettings.setDatabaseEnabled(true);
        
        webView.setWebViewClient(new WebViewClient());
        // Connects directly to your local server daemon running on port 51201
        webView.loadUrl("http://127.0.0.1:51201");
        
        setContentView(webView);
    }

    @Override
    public void onBackPressed() {
        if (webView.canGoBack()) {
            webView.goBack();
        } else {
            super.onBackPressed();
        }
    }
}
EOM

echo "[+] Android project files successfully written under android_apk_project/"
echo "[+] Ready for APK compilation."
`;

fs.writeFileSync('build_apk.sh', buildScript);
fs.chmodSync('build_apk.sh', '755');
console.log("[+] Build pipeline script successfully created: ./build_apk.sh");
