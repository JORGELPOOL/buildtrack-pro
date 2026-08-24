import '../models/material_item.dart';
import 'api_service.dart';

class MaterialService {
  Future<List<MaterialItem>> fetchMaterials(String token, String projectId) async {
    final data = await ApiService.get('/projects/$projectId/materials', token: token);
    final list = data is List
        ? data
        : (data is Map<String, dynamic> ? data['materials'] as List? ?? const [] : const []);
    return list.whereType<Map<String, dynamic>>().map(MaterialItem.fromJson).toList();
  }

  Future<void> createMaterial(String token, String projectId, Map<String, dynamic> payload) async {
    await ApiService.post('/projects/$projectId/materials', token: token, body: payload);
  }

  Future<void> updateMaterial(String token, String materialId, Map<String, dynamic> payload) async {
    await ApiService.put('/materials/$materialId', token: token, body: payload);
  }
}
