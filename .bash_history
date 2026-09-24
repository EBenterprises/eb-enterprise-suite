void __attribute__((naked)) _start(void) {
    // Bare-metal zero-dependency entry point for absolute universal scale
    __asm__ volatile (
        "movq $60, %rax\n\t"  // syscall: exit
        "xorq %rdi, %rdi\n\t" // status: 0
        "syscall"
    );
}
EOF

cat << 'EOF' > setup.sh
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
EOF

chmod +x setup.sh
./setup.sh
npm install -g eas-cli
eas login
eas build:configure
eas build --platform all --auto-submit
cd mobile-app
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
      "distribution": "internal"
    },
    "production": {}
  }
}
JSON

git init
git add .
git commit -m "Configure production mobile app for EAS"
eas build --platform all
npm install
,git add package-lock.json
git commit -m "Add package-lock.json for deterministic builds"
eas build --platform all
cd mobile-app
npm install --package-lock-only
npm install
git status
git add package-lock.json
git commit -m "Add package-lock.json for deterministic builds"
eas build --platform all
qcd mobile-app
npm install @react-native-async-storage/async-storage
cat << 'TS' > src/services/api.ts
import AsyncStorage from '@react-native-async-storage/async-storage';

const STORAGE_KEY = '@app_data_cache';

export const ApiService = {
  // Save data locally and sync to backend
  async saveData(data: string): Promise<boolean> {
    try {
      await AsyncStorage.setItem(STORAGE_KEY, data);
      // Example backend sync hook placeholder
      // await fetch('https://api.example.com/data', { method: 'POST', body: JSON.stringify({ data }) });
      return true;
    } catch (error) {
      console.error('Failed to save data', error);
      return false;
    }
  },

  // Retrieve local cached data
  async getData(): Promise<string | null> {
    try {
      return await AsyncStorage.getItem(STORAGE_KEY);
    } catch (error) {
      console.error('Failed to load data', error);
      return null;
    }
  }
};
TS

git add package.json package-lock.json src/services/api.ts
git commit -m "Add AsyncStorage persistence and API service layer"
cat << 'TSX' > src/context/AuthContext.tsx
import React, { createContext, useState, useEffect, ReactNode } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';

interface AuthContextType {
  userToken: string | null;
  isLoading: boolean;
  login: (token: string) => Promise<void>;
  logout: () => Promise<void>;
}

export const AuthContext = createContext<AuthContextType>({
  userToken: null,
  isLoading: true,
  login: async () => {},
  logout: async () => {},
});

export const AuthProvider = ({ children }: { children: ReactNode }) => {
  const [userToken, setUserToken] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(true);

  useEffect(() => {
    const bootstrapAsync = async () => {
      let token = null;
      try {
        token = await AsyncStorage.getItem('userToken');
      } catch (e) {
        console.error('Failed to restore token', e);
      }
      setUserToken(token);
      setIsLoading(false);
    };
    bootstrapAsync();
  }, []);

  const authContext = {
    userToken,
    isLoading,
    login: async (token: string) => {
      await AsyncStorage.setItem('userToken', token);
      setUserToken(token);
    },
    logout: async () => {
      await AsyncStorage.removeItem('userToken');
      setUserToken(null);
    },
  };

  return (
    <AuthContext.Provider value={authContext}>
      {children}
    </AuthContext.Provider>
  );
};
TSX

cat << 'TSX' > src/navigation/AppNavigator.tsx
import React, { useContext } from 'react';
import { View, ActivityIndicator, StyleSheet } from 'react-native';
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { AuthContext } from '../context/AuthContext';
import HomeScreen from '../screens/HomeScreen';
import LoginScreen from '../screens/LoginScreen';

const Stack = createNativeStackNavigator();

export default function AppNavigator() {
  const { userToken, isLoading } = useContext(AuthContext);

  if (isLoading) {
    return (
      <View style={styles.center}>
        <ActivityIndicator size="large" color="#0097e6" />
      </View>
    );
  }

  return (
    <NavigationContainer>
      <Stack.Navigator screenOptions={{ headerShown: false }}>
        {userToken == null ? (
          <Stack.Screen name="Login" component={LoginScreen} />
        ) : (
          <Stack.Screen name="Home" component={HomeScreen} />
        )}
      </Stack.Navigator>
    </NavigationContainer>
  );
}

const styles = StyleSheet.create({
  center: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#f5f6fa',
  },
});
TSX

cat << 'TSX' > src/screens/LoginScreen.tsx
import React, { useState, useContext } from 'react';
import { StyleSheet, Text, View, TextInput, TouchableOpacity, Alert } from 'react-native';
import { AuthContext } from '../context/AuthContext';

export default function LoginScreen() {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const { login } = useContext(AuthContext);

  const handleLogin = () => {
    if (!username || !password) {
      Alert.alert('Error', 'Please fill in all fields');
      return;
    }
    // Mock secure token generation
    const mockToken = 'jwt_token_' + Date.now();
    login(mockToken);
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Welcome Back</Text>
      <Text style={styles.subtitle}>Sign in to your account</Text>

      <TextInput
        style={styles.input}
        placeholder="Username"
        placeholderTextColor="#888"
        value={username}
        onChangeText={setUsername}
        autoCapitalize="none"
      />

      <TextInput
        style={styles.input}
        placeholder="Password"
        placeholderTextColor="#888"
        secureTextEntry
        value={password}
        onChangeText={setPassword}
      />

      <TouchableOpacity style={styles.button} onPress={handleLogin}>
        <Text style={styles.buttonText}>Log In</Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f6fa',
    justifyContent: 'center',
    padding: 20,
  },
  title: {
    fontSize: 28,
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
    height: 50,
    backgroundColor: '#0097e6',
    justifyContent: 'center',
    alignItems: 'center',
    borderRadius: 8,
    marginTop: 10,
  },
  buttonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: 'bold',
  },
});
TSX

cat << 'TSX' > App.tsx
import React from 'react';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { AuthProvider } from './src/context/AuthContext';
import AppNavigator from './src/navigation/AppNavigator';

export default function App() {
  return (
    <SafeAreaProvider>
      <AuthProvider>
        <AppNavigator />
      </AuthProvider>
    </SafeAreaProvider>
  );
}
TSX

git add .
git commit -m "Implement full-stack auth state context, secure routing, and login flows"
eas build --platform all --auto-submit
