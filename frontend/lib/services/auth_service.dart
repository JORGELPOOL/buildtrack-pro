import '../models/user.dart';
import 'api_service.dart';

class AuthLoginResult {
  const AuthLoginResult({required this.token, required this.user});

  final String token;
  final User user;
}

class AuthService {
  Future<AuthLoginResult> login({
    required String email,
    required String password,
  }) async {
    final data = await ApiService.post(
      '/auth/login',
      body: {
        'email': email,
        'password': password,
      },
    );

    if (data is! Map<String, dynamic>) {
      throw ApiException('Unexpected login response');
    }

    final token = data['token']?.toString() ?? '';
    final userJson = (data['user'] is Map<String, dynamic>)
        ? data['user'] as Map<String, dynamic>
        : <String, dynamic>{};

    if (token.isEmpty) {
      throw ApiException('Authentication token missing in response');
    }

    return AuthLoginResult(
      token: token,
      user: User.fromJson(userJson),
    );
  }

  Future<void> createStaff({
    required String token,
    required String email,
    required String name,
    required String password,
  }) async {
    await ApiService.post(
      '/auth/staff',
      token: token,
      body: {
        'email': email,
        'name': name,
        'password': password,
      },
    );
  }
}
