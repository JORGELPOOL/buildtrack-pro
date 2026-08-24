import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoggedIn;
  const LoginScreen({super.key, required this.onLoggedIn});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController(text: 'admin@buildtrack.com');
  final _password = TextEditingController(text: 'Admin123!');
  bool _busy = false;
  String? _error;

  Future<void> _login() async {
    setState(() { _busy = true; _error = null; });
    try {
      await AuthService().login(_email.text.trim(), _password.text);
      widget.onLoggedIn();
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(children: [
        Expanded(
          flex: 5,
          child: Container(
            color: const Color(0xFF173B57),
            padding: const EdgeInsets.all(64),
            child: const Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.apartment_rounded, size: 64, color: Colors.white),
              SizedBox(height: 24),
              Text('BuildTrack Pro', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w800, color: Colors.white)),
              SizedBox(height: 16),
              Text('Projects, budgets, workers, materials, progress photos and client reports — managed in one place.', style: TextStyle(fontSize: 18, height: 1.6, color: Color(0xFFD7E5EF))),
            ]),
          ),
        ),
        Expanded(
          flex: 4,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    const Text('Sign in', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Administrator and staff access'),
                    const SizedBox(height: 28),
                    TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
                    const SizedBox(height: 16),
                    TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder())),
                    if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: const TextStyle(color: Colors.red))),
                    const SizedBox(height: 22),
                    FilledButton(onPressed: _busy ? null : _login, child: Padding(padding: const EdgeInsets.all(14), child: Text(_busy ? 'Signing in...' : 'Sign in'))),
                    const SizedBox(height: 14),
                    const Text('Demo admin: admin@buildtrack.com / Admin123!', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
                  ]),
                ),
              ),
            ),
          ),
        )
      ]),
    );
  }
}
