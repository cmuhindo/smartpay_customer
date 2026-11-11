import 'package:flutter/material.dart';

import 'core/api_client.dart';
import 'models/models.dart';
import 'screens/cases_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SmartPayApp());
}

class SmartPayApp extends StatefulWidget {
  const SmartPayApp({super.key});

  @override
  State<SmartPayApp> createState() => _SmartPayAppState();
}

class _SmartPayAppState extends State<SmartPayApp> {
  final ApiClient api = ApiClient();
  UserProfile? user;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    UserProfile? restoredUser;
    final storedToken = await api.token;

    if (storedToken != null) {
      try {
        final currentUser = await api.me();
        if (!currentUser.mustChangePassword) {
          restoredUser = currentUser;
        } else {
          await api.clearLocalSession();
        }
      } catch (_) {
        await api.clearLocalSession();
      }
    }

    if (mounted) {
      setState(() {
        user = restoredUser;
        loading = false;
      });
    }
  }

  void _onLogin(UserProfile profile) => setState(() => user = profile);

  Future<void> _onLogout() async {
    await api.logout();
    if (mounted) setState(() => user = null);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartPay',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B7285)),
        scaffoldBackgroundColor: const Color(0xFFF5F8FA),
        inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
        cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero),
      ),
      home: loading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : user == null
          ? LoginScreen(api: api, onLogin: _onLogin)
          : HomeShell(api: api, user: user!, onLogout: _onLogout),
    );
  }
}

class HomeShell extends StatefulWidget {
  final ApiClient api;
  final UserProfile user;
  final Future<void> Function() onLogout;

  const HomeShell({super.key, required this.api, required this.user, required this.onLogout});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(api: widget.api, user: widget.user),
      CasesScreen(api: widget.api),
      ProfileScreen(user: widget.user, onLogout: widget.onLogout),
    ];

    return Scaffold(
      body: pages[selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (value) => setState(() => selectedIndex = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.support_agent_outlined), selectedIcon: Icon(Icons.support_agent), label: 'Support'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
