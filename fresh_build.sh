#!/bin/bash
set -e

echo "===================================================="
echo "Initializing Fresh Full-Stack Native Mobile Project..."
echo "===================================================="

# 1. Clean up old directory if it exists and create a fresh one
rm -rf mobile-app
mkdir -p mobile-app/assets mobile-app/src/components mobile-app/src/context mobile-app/src/screens mobile-app/src/navigation mobile-app/src/services
cd mobile-app

# 2. Package Configuration
echo "[1/6] Generating package.json..."
cat << 'JSON' > package.json
{
  "name": "native-mobile-app-fresh",
  "version": "1.0.0",
  "scripts": {
    "start": "expo start",
    "android": "expo start --android",
    "ios": "expo start --ios",
    "web": "expo start --web",
    "build:apk": "eas build --platform android --profile preview"
  },
  "dependencies": {
    "@react-native-async-storage/async-storage": "1.23.1",
    "@react-navigation/native": "^6.1.9",
    "@react-navigation/native-stack": "^6.9.17",
    "expo": "~51.0.0",
    "expo-device": "~6.0.2",
    "expo-notifications": "~0.28.9",
    "expo-status-bar": "~1.12.1",
    "react": "18.2.0",
    "react-native": "0.74.1",
    "react-native-safe-area-context": "4.10.5",
    "react-native-screens": "3.31.1"
  },
  "devDependencies": {
    "@babel/core": "^7.20.0",
    "@types/react": "~18.2.45",
    "typescript": "~5.3.3"
  },
  "private": true
}
JSON

# 3. Expo & EAS Manifests (Configured for direct APK output)
echo "[2/6] Generating app.json and eas.json..."
cat << 'JSON' > app.json
{
  "expo": {
    "name": "Native Mobile App",
    "slug": "native-mobile-app-fresh",
    "version": "1.0.0",
    "orientation": "portrait",
    "icon": "./assets/icon.png",
    "userInterfaceStyle": "automatic",
    "splash": {
      "image": "./assets/splash.png",
      "resizeMode": "contain",
      "backgroundColor": "#ffffff"
    },
    "ios": {
      "supportsTablet": true,
      "bundleIdentifier": "com.example.nativeappfresh"
    },
    "android": {
      "adaptiveIcon": {
        "foregroundImage": "./assets/adaptive-icon.png",
        "backgroundColor": "#ffffff"
      },
      "package": "com.example.nativeappfresh"
    },
    "web": {
      "bundler": "metro"
    }
  }
}
JSON

cat << 'JSON' > eas.json
{
  "cli": {
    "version": ">= 14.4.1",
    "appVersionSource": "remote",
    "requireCommit": true
  },
  "build": {
    "development": {
      "developmentClient": true,
      "distribution": "internal"
    },
    "preview": {
      "android": {
        "buildType": "apk"
      },
      "distribution": "internal"
    },
    "production": {}
  }
}
JSON

# 4. Generate Placeholder Assets
echo "[3/6] Generating placeholder app icons and splash screens..."
echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=" | base64 -d > assets/icon.png
echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=" | base64 -d > assets/splash.png
echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=" | base64 -d > assets/adaptive-icon.png

cat << 'EOF' > .easignore
node_modules/
.expo/
android/
ios/
