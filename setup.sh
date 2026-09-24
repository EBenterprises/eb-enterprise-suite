#!/bin/bash
set -e

echo "Creating project directories..."
mkdir -p mobile-app/assets mobile-app/src/components mobile-app/src/screens mobile-app/src/navigation mobile-app/src/services
cd mobile-app

echo "Generating package.json..."
cat << 'JSON' > package.json
{
  "name": "native-mobile-app",
  "version": "1.0.0",
  "scripts": {
    "start": "expo start",
    "android": "expo start --android",
    "ios": "expo start --ios",
    "web": "expo start --web",
    "build:prod": "eas build --platform all"
  },
  "dependencies": {
    "@react-navigation/native": "^6.1.9",
    "@react-navigation/native-stack": "^6.9.17",
    "expo": "~51.0.0",
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

echo "Generating app.json..."
cat << 'JSON' > app.json
{
  "expo": {
    "name": "Native Mobile App",
    "slug": "native-mobile-app",
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
      "bundleIdentifier": "com.example.nativeapp"
    },
    "android": {
      "adaptiveIcon": {
        "foregroundImage": "./assets/adaptive-icon.png",
        "backgroundColor": "#ffffff"
      },
      "package": "com.example.nativeapp"
    },
    "web": {
      "bundler": "metro"
    }
  }
}
JSON

echo "Generating App.tsx..."
cat << 'TSX' > App.tsx
import React from 'react';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import AppNavigator from './src/navigation/AppNavigator';

export default function App() {
  return (
    <SafeAreaProvider>
      <AppNavigator />
    </SafeAreaProvider>
  );
}
TSX

echo "Generating Home Screen..."
cat << 'TSX' > src/screens/HomeScreen.tsx
import React, { useState } from 'react';
import { StyleSheet, Text, View, TextInput, TouchableOpacity, Alert } from 'react-native';

export default function HomeScreen() {
  const [text, setText] = useState('');

  const handlePress = () => {
    if (!text.trim()) {
      Alert.alert('Error', 'Please enter some text!');
      return;
    }
    Alert.alert('Success', `You entered: ${text}`);
    setText('');
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Native App Dashboard</Text>
      <Text style={styles.subtitle}>Full-Stack Cross-Platform Template</Text>
      
      <TextInput
        style={styles.input}
        placeholder="Type something..."
        placeholderTextColor="#888"
        value={text}
        onChangeText={setText}
      />
      
      <TouchableOpacity style={styles.button} onPress={handlePress}>
        <Text style={styles.buttonText}>Submit Data</Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f6fa',
    alignItems: 'center',
    justifyContent: 'center',
    padding: 20,
  },
  title: {
    fontSize: 26,
    fontWeight: 'bold',
    color: '#2f3640',
    marginBottom: 5,
  },
  subtitle: {
    fontSize: 16,
    color: '#718093',
    marginBottom: 30,
  },
  input: {
    width: '100%',
    height: 50,
    backgroundColor: '#fff',
    borderWidth: 1,
    borderColor: '#dcdde1',
    borderRadius: 8,
    paddingHorizontal: 15,
    fontSize: 16,
    marginBottom: 15,
  },
  button: {
    width: '100%',
    height: 50,
    backgroundColor: '#0097e6',
    justifyContent: 'center',
    alignItems: 'center',
    borderRadius: 8,
  },
  buttonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: 'bold',
  },
});
TSX

echo "Generating AppNavigator.tsx..."
cat << 'TSX' > src/navigation/AppNavigator.tsx
import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import HomeScreen from '../screens/HomeScreen';

const Stack = createNativeStackNavigator();

export default function AppNavigator() {
  return (
    <NavigationContainer>
      <Stack.Navigator initialRouteName="Home">
        <Stack.Screen 
          name="Home" 
          component={HomeScreen} 
          options={{ title: 'Welcome' }} 
        />
      </Stack.Navigator>
    </NavigationContainer>
  );
}
TSX

echo "Setup completed successfully inside ./mobile-app!"
