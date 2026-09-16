#!/bin/bash
set -e

PROJECT_DIR="$HOME/native-android-app"
echo "[*] Initializing workspace configuration at $PROJECT_DIR..."

mkdir -p "$PROJECT_DIR/app/src/main/java/com/example/nativeapp"
mkdir -p "$PROJECT_DIR/app/src/main/res/layout"
mkdir -p "$PROJECT_DIR/app/src/main/res/values"
mkdir -p "$PROJECT_DIR/app/src/main/assets"

cat << 'MANIFEST' > "$PROJECT_DIR/app/src/main/AndroidManifest.xml"
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.nativeapp">

    <application
        android:allowBackup="true"
        android:icon="@mipmap/ic_launcher"
        android:label="NativeTermuxApp"
        android:roundIcon="@mipmap/ic_launcher_round"
        android:supportsRtl="true"
        android:theme="@style/Theme.AppCompat.Light.NoActionBar">
        <activity
            android:name=".MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>

</manifest>
MANIFEST

cat << 'LAYOUT' > "$PROJECT_DIR/app/src/main/res/layout/activity_main.xml"
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:gravity="center"
    android:padding="24dp"
    android:background="#121212">

    <TextView
        android:id="@+id/titleText"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="Native Termux App"
        android:textSize="24sp"
        android:textColor="#FFFFFF"
        android:textStyle="bold"
        android:layout_marginBottom="16dp"/>

    <Button
        android:id="@+id/actionButton"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="Click Me"
        android:backgroundTint="#6200EE"
        android:textColor="#FFFFFF"/>

</LinearLayout>
LAYOUT

cat << 'STRINGS' > "$PROJECT_DIR/app/src/main/res/values/strings.xml"
<resources>
    <string name="app_name">NativeTermuxApp</string>
</resources>
STRINGS

cat << 'JAVA' > "$PROJECT_DIR/app/src/main/java/com/example/nativeapp/MainActivity.java"
package com.example.nativeapp;

import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;
import androidx.appcompat.app.AppCompatActivity;

public class MainActivity extends AppCompatActivity {
    private int clickCount = 0;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        final TextView titleText = findViewById(R.id.titleText);
        Button actionButton = findViewById(R.id.actionButton);

        actionButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                clickCount++;
                titleText.setText("Clicked: " + clickCount + " times");
            }
        });
    }
}
JAVA

cat << 'APPGRADLE' > "$PROJECT_DIR/app/build.gradle"
plugins {
    id 'com.android.application'
}

android {
    namespace 'com.example.nativeapp'
    compileSdk 33

    defaultConfig {
        applicationId "com.example.nativeapp"
        minSdk 21
        targetSdk 33
        versionCode 1
        versionName "1.0"
    }

    buildTypes {
        release {
            minifyEnabled false
        }
    }
}

dependencies {
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'com.google.android.material:material:1.9.0'
}
APPGRADLE

cat << 'ROOTGRADLE' > "$PROJECT_DIR/build.gradle"
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:8.1.0'
    }
}
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
ROOTGRADLE

cat << 'SETTINGS' > "$PROJECT_DIR/settings.gradle"
rootProject.name = "NativeTermuxApp"
include ':app'
SETTINGS

cd "$PROJECT_DIR"

if ! command -v gradle &> /dev/null; then
    wget -q https://services.gradle.org/distributions/gradle-8.2-bin.zip
    unzip -qo gradle-8.2-bin.zip
    export PATH="$PWD/gradle-8.2/bin:$PATH"
fi

echo "[*] Triggering live APK build isolating Java environment parameters..."
unset JAVA_TOOL_OPTIONS
export _JAVA_OPTIONS=""
export GRADLE_OPTS="-Xmx1g -Dorg.gradle.jvmargs='-Xmx1g -XX:+UseG1GC' -Dorg.gradle.daemon=false"
gradle assembleDebug --no-daemon

echo "[*] Build finished! APK located at:"
echo "$PROJECT_DIR/app/build/outputs/apk/debug/app-debug.apk"
