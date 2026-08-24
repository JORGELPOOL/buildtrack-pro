import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../models/photo.dart';
import 'api_service.dart';

class PhotoService {
  Future<List<Photo>> fetchPhotos(String token, String projectId) async {
    final data = await ApiService.get('/projects/$projectId/photos', token: token);
    final list = data is List
        ? data
        : (data is Map<String, dynamic> ? data['photos'] as List? ?? const [] : const []);
    return list.whereType<Map<String, dynamic>>().map(Photo.fromJson).toList();
  }

  Future<void> uploadPhoto({
    required String token,
    required String projectId,
    required Uint8List bytes,
    required String fileName,
    String? caption,
  }) async {
    await ApiService.multipartPost(
      '/projects/$projectId/photos',
      token: token,
      fields: {
        if (caption != null && caption.isNotEmpty) 'caption': caption,
      },
      files: [
        http.MultipartFile.fromBytes(
          'photo',
          bytes,
          filename: fileName,
        ),
      ],
    );
  }
}
