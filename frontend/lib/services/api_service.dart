import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ApiService {
  final _auth = AuthService();
  Future<Map<String, String>> _headers() async => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${await _auth.getToken()}',
  };

  Future<List<dynamic>> getList(String path) async {
    final r = await http.get(Uri.parse('${AuthService.apiUrl}$path'), headers: await _headers());
    if (r.statusCode >= 400) throw Exception(jsonDecode(r.body)['error'] ?? 'Request failed');
    return jsonDecode(r.body) as List<dynamic>;
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final r = await http.post(Uri.parse('${AuthService.apiUrl}$path'), headers: await _headers(), body: jsonEncode(body));
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    if (r.statusCode >= 400) throw Exception(data['error'] ?? 'Request failed');
    return data;
  }
}
