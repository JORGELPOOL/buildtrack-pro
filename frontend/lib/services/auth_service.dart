import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const apiUrl = String.fromEnvironment('API_URL', defaultValue: 'https://buildtrack-pro-production-7a75.up.railway.app/api');

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(Uri.parse('$apiUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}));
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400) throw Exception(data['error'] ?? 'Login failed');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', data['token']);
    await prefs.setString('user', jsonEncode(data['user']));
    return data;
  }

  Future<String?> getToken() async => (await SharedPreferences.getInstance()).getString('token');

  Future<Map<String, dynamic>?> getUser() async {
    final raw = (await SharedPreferences.getInstance()).getString('user');
    return raw == null ? null : jsonDecode(raw);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }
}
