import '../models/project.dart';
import 'api_service.dart';

class ProjectService {
  Future<List<Project>> fetchProjects(String token) async {
    final data = await ApiService.get('/projects', token: token);
    final list = data is List
        ? data
        : (data is Map<String, dynamic> ? data['projects'] as List? ?? const [] : const []);
    return list
        .whereType<Map<String, dynamic>>()
        .map(Project.fromJson)
        .toList();
  }

  Future<Project> fetchProject(String token, String id) async {
    final data = await ApiService.get('/projects/$id', token: token);
    final json = data is Map<String, dynamic>
        ? ((data['project'] is Map<String, dynamic>) ? data['project'] as Map<String, dynamic> : data)
        : <String, dynamic>{};
    return Project.fromJson(json);
  }

  Future<Project> createProject(String token, Map<String, dynamic> payload) async {
    final data = await ApiService.post('/projects', token: token, body: payload);
    final json = data is Map<String, dynamic>
        ? ((data['project'] is Map<String, dynamic>) ? data['project'] as Map<String, dynamic> : data)
        : <String, dynamic>{};
    return Project.fromJson(json);
  }

  Future<Project> updateProject(String token, String id, Map<String, dynamic> payload) async {
    final data = await ApiService.put('/projects/$id', token: token, body: payload);
    final json = data is Map<String, dynamic>
        ? ((data['project'] is Map<String, dynamic>) ? data['project'] as Map<String, dynamic> : data)
        : <String, dynamic>{};
    return Project.fromJson(json);
  }

  Future<void> deleteProject(String token, String id) async {
    await ApiService.delete('/projects/$id', token: token);
  }
}
