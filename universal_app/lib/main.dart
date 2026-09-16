import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

void main() {
  runApp(const UniversalEnterpriseApp());
}

class UniversalEnterpriseApp extends StatefulWidget {
  const UniversalEnterpriseApp({super.key});

  @override
  State<UniversalEnterpriseApp> createState() => _UniversalEnterpriseAppState();
}

class _UniversalEnterpriseAppState extends State<UniversalEnterpriseApp> {
  bool _isDarkMode = false;

  void toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Universal Enterprise Suite',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo, brightness: Brightness.light),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => LoginScreen(onThemeToggle: toggleTheme, isDarkMode: _isDarkMode),
        '/signup': (context) => SignupScreen(onThemeToggle: toggleTheme, isDarkMode: _isDarkMode),
        '/forgot': (context) => const ForgotPasswordScreen(),
        '/main_nav': (context) => MainNavigationShell(onThemeToggle: toggleTheme, isDarkMode: _isDarkMode),
      },
    );
  }
}

// 1. Splash Screen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      Navigator.pushReplacementNamed(context, '/onboarding');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.hub, size: 100, color: Colors.white),
              SizedBox(height: 24),
              Text(
                'Universal Enterprise Suite',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              SizedBox(height: 8),
              Text(
                'Multi-Platform Ecosystem Engine',
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
              SizedBox(height: 48),
              CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

// 2. Onboarding Screen
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const Icon(Icons.devices_other, size: 120, color: Colors.indigo),
              const SizedBox(height: 32),
              const Text(
                'Deploy Everywhere',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Access fully featured workflows across mobile, desktop, and web environments with a unified reactive interface.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pushReplacementNamed(context, '/signup'),
                child: const Text('Get Started', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                child: const Text('Already have an account? Sign In'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 3. Signup Screen
class SignupScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final bool isDarkMode;

  const SignupScreen({super.key, required this.onThemeToggle, required this.isDarkMode});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();

  void _signup() {
    if (_nameController.text.isNotEmpty && _emailController.text.isNotEmpty && _passController.text.isNotEmpty) {
      Navigator.pushReplacementNamed(context, '/main_nav');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all registration fields')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('User Registration', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder())),
                const SizedBox(height: 16),
                TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder())),
                const SizedBox(height: 16),
                TextField(controller: _passController, obscureText: true, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder())),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                  onPressed: _signup,
                  child: const Text('Create Account', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                  child: const Text('Already registered? Sign In'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 4. Login Screen
class LoginScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final bool isDarkMode;

  const LoginScreen({super.key, required this.onThemeToggle, required this.isDarkMode});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();

  void _login() {
    if (_emailController.text.isNotEmpty && _passController.text.isNotEmpty) {
      Navigator.pushReplacementNamed(context, '/main_nav');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid email and password')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Welcome Back', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder())),
                const SizedBox(height: 16),
                TextField(controller: _passController, obscureText: true, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder())),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/forgot'),
                    child: const Text('Forgot Password?'),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                  onPressed: _login,
                  child: const Text('Sign In', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/signup'),
                  child: const Text("Don't have an account? Sign Up"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 5. Forgot Password Screen
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Password Recovery')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Enter your registered email to receive secure recovery instructions.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            const TextField(decoration: InputDecoration(labelText: 'Email Address', border: OutlineInputBorder())),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Recovery instructions sent!')),
                );
                Navigator.pop(context);
              },
              child: const Text('Send Recovery Link', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

// 6. Main Navigation Shell (Bottom Navigation Bar with 4 Full Pages)
class MainNavigationShell extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final bool isDarkMode;

  const MainNavigationShell({super.key, required this.onThemeToggle, required this.isDarkMode});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const HomeTab(),
      const AnalyticsTab(),
      const NotificationsTab(),
      SettingsTab(onThemeToggle: widget.onThemeToggle, isDarkMode: widget.isDarkMode),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Analytics'),
          NavigationDestination(icon: Icon(Icons.notifications_outlined), selectedIcon: Icon(Icons.notifications), label: 'Notifications'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

// Tab 1: Home Dashboard
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  String _resolvePlatform() {
    if (kIsWeb) return "Web Browser";
    if (Platform.isAndroid) return "Google Play (Android)";
    if (Platform.isIOS) return "App Store (iOS)";
    if (Platform.isMacOS) return "Mac App Store (macOS)";
    if (Platform.isWindows) return "Microsoft Store (Windows)";
    if (Platform.isLinux) return "Linux Package Manager";
    return "Multi-Platform Matrix";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enterprise Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.verified, size: 44, color: Colors.indigo),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Active Target Runtime', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(_resolvePlatform(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Quick Metrics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: const [
              Expanded(child: MetricCard(title: 'Active Users', value: '24,592', icon: Icons.group, color: Colors.blue)),
              SizedBox(width: 12),
              Expanded(child: MetricCard(title: 'System Health', value: '99.9%', icon: Icons.health_and_safety, color: Colors.green)),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Active Modules', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const ListTile(
            leading: Icon(Icons.check_circle, color: Colors.green),
            title: Text('Splash & Auth Workflow'),
            subtitle: Text('Operational across all app stores'),
          ),
          const ListTile(
            leading: Icon(Icons.check_circle, color: Colors.green),
            title: Text('Multi-Tab Navigation Shell'),
            subtitle: Text('Declarative routing and state persistence'),
          ),
          const ListTile(
            leading: Icon(Icons.check_circle, color: Colors.green),
            title: Text('Dynamic Theme Switcher'),
            subtitle: Text('Seamless light and dark mode integration'),
          ),
        ],
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const MetricCard({super.key, required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// Tab 2: Analytics Tab
class AnalyticsTab extends StatelessWidget {
  const AnalyticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Performance Analytics')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ecosystem Distribution', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: const [
                  ListTile(title: Text('Google Play Store (Android)'), trailing: Text('42%')),
                  LinearProgressIndicator(value: 0.42),
                  SizedBox(height: 16),
                  ListTile(title: Text('Apple App Store (iOS & macOS)'), trailing: Text('35%')),
                  LinearProgressIndicator(value: 0.35),
                  SizedBox(height: 16),
                  ListTile(title: Text('Microsoft Store (Windows)'), trailing: Text('15%')),
                  LinearProgressIndicator(value: 0.15),
                  SizedBox(height: 16),
                  ListTile(title: Text('Web Browser & Linux'), trailing: Text('8%')),
                  LinearProgressIndicator(value: 0.08),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Tab 3: Notifications Tab
class NotificationsTab extends StatelessWidget {
  const NotificationsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('System Notifications')),
      body: ListView(
        children: const [
          ListTile(
            leading: Icon(Icons.system_update, color: Colors.indigo),
            title: Text('Universal Build v1.0.0 Deployed'),
            subtitle: Text('Successfully compiled for all target stores.'),
            trailing: Text('10m ago', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.security, color: Colors.green),
            title: Text('Security Token Refreshed'),
            subtitle: Text('OAuth session handshake completed securely.'),
            trailing: Text('2h ago', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.group_add, color: Colors.blue),
            title: Text('New Enterprise Node Connected'),
            subtitle: Text('Client workspace provisioned successfully.'),
            trailing: Text('1d ago', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// Tab 4: Settings Tab
class SettingsTab extends StatelessWidget {
  final VoidCallback onThemeToggle;
  final bool isDarkMode;

  const SettingsTab({super.key, required this.onThemeToggle, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('App Settings')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Preferences', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
          ),
          SwitchListTile(
            title: const Text('Dark Appearance Mode'),
            subtitle: const Text('Toggle high-contrast dark theme palette'),
            value: isDarkMode,
            onChanged: (val) => onThemeToggle(),
            secondary: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Account Management', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profile Credentials'),
            subtitle: const Text('Manage user ID and access tokens'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile management view open')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Security & Privacy'),
            subtitle: const Text('Configure biometric lock and encryption'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Security configuration view open')),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
            subtitle: const Text('Terminate active session'),
            onTap: () {
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
          ),
        ],
      ),
    );
  }
}
