const fs = require('fs');
const { execSync } = require('child_process');

console.log("[+] Creating directory tree and bundling v5 Sales Tracker with Interactive Map Picker...");

const projDir = './android_v5_apk_project';
const targetSrcDir = `${projDir}/app/src/main/java/com/ebenterprises/salestracker/v5`;

fs.mkdirSync(targetSrcDir, { recursive: true });
fs.mkdirSync(`${projDir}/app/src/main/res/values`, { recursive: true });

// 1. AndroidManifest.xml
const manifest = `<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.ebenterprises.salestracker.v5">

    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.WAKE_LOCK" />

    <application
        android:allowBackup="true"
        android:label="EB Sales Tracker v5"
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
</manifest>`;

fs.writeFileSync(`${projDir}/app/src/main/AndroidManifest.xml`, manifest);

// 2. MainActivity.java with Geolocation/Map Picker Support
const mainActivity = `package com.ebenterprises.salestracker.v5;

import android.app.Activity;
import android.os.Bundle;
import android.webkit.GeolocationPermissions;
import android.webkit.WebChromeClient;
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
        webSettings.setGeolocationEnabled(true);

        webView.setWebViewClient(new WebViewClient());
        webView.setWebChromeClient(new WebChromeClient() {
            @Override
            public void onGeolocationPermissionsShowPrompt(String origin, GeolocationPermissions.Callback callback) {
                callback.invoke(origin, true, false);
            }
        });

        // Points directly to your running v5 Sales Tracker server daemon with interactive map picker
        webView.loadUrl("http://127.0.0.1:51205");

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
`;

fs.writeFileSync(`${targetSrcDir}/MainActivity.java`, mainActivity);

// 3. Package archive
try {
    execSync(`tar -czf eb_sales_tracker_v5_map_picker_apk.tar.gz ${projDir}`, { stdio: 'inherit' });
    console.log("\n[+] SUCCESS! v5 Sales Tracker with Interactive Map Picker packaged into:");
    console.log("    ~/sales-tracker/eb_sales_tracker_v5_map_picker_apk.tar.gz");
} catch (e) {
    console.log("[-] Failed to create archive.");
}
