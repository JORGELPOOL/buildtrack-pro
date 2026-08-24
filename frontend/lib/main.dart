import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'services/auth_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ConstructionManagerApp());
}

class ConstructionManagerApp extends StatefulWidget {
  const ConstructionManagerApp({super.key});
  @override
  State<ConstructionManagerApp> createState() => _ConstructionManagerAppState();
}

class _ConstructionManagerAppState extends State<ConstructionManagerApp> {
  final AuthService _auth = AuthService();
  bool _loading = true;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final token = await _auth.getToken();
    setState(() {
      _loggedIn = token != null;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BuildTrack Pro',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF173B57)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      ),
      home: _loading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _loggedIn
              ? DashboardScreen(onLogout: () => setState(() => _loggedIn = false))
              : LoginScreen(onLoggedIn: () => setState(() => _loggedIn = true)),
    );
  }
}
