import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiService {
  static Uri _uri(String path) {
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('${ApiConfig.baseUrl}$normalized');
  }

  static Map<String, String> _headers({String? token, bool json = true}) {
    return {
      if (json) 'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer ' + token,
    };
  }

  static dynamic _decodeResponse(http.Response response) {
    final body = response.body.trim();
    dynamic decoded;
    if (body.isNotEmpty) {
      try {
        decoded = jsonDecode(body);
      } catch (_) {
        decoded = body;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    var message = 'Request failed (${response.statusCode})';
    if (decoded is Map<String, dynamic>) {
      message = decoded['message']?.toString() ??
          decoded['error']?.toString() ??
          decoded['detail']?.toString() ??
          message;
    } else if (decoded is String && decoded.isNotEmpty) {
      message = decoded;
    }

    throw ApiException(message, statusCode: response.statusCode);
  }

  static Future<dynamic> get(String path, {String? token}) async {
    final response = await http.get(_uri(path), headers: _headers(token: token, json: false));
    return _decodeResponse(response);
  }

  static Future<dynamic> post(String path, {String? token, Object? body}) async {
    final response = await http.post(
      _uri(path),
      headers: _headers(token: token),
      body: body == null ? null : jsonEncode(body),
    );
    return _decodeResponse(response);
  }

  static Future<dynamic> put(String path, {String? token, Object? body}) async {
    final response = await http.put(
      _uri(path),
      headers: _headers(token: token),
      body: body == null ? null : jsonEncode(body),
    );
    return _decodeResponse(response);
  }

  static Future<dynamic> delete(String path, {String? token}) async {
    final response = await http.delete(_uri(path), headers: _headers(token: token, json: false));
    return _decodeResponse(response);
  }

  static Future<dynamic> multipartPost(
    String path, {
    String? token,
    Map<String, String>? fields,
    List<http.MultipartFile>? files,
  }) async {
    final request = http.MultipartRequest('POST', _uri(path))
      ..headers.addAll(_headers(token: token, json: false));
    if (fields != null) {
      request.fields.addAll(fields);
    }
    if (files != null) {
      request.files.addAll(files);
    }
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _decodeResponse(response);
  }
}
