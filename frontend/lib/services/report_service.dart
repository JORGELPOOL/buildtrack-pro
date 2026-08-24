import 'api_service.dart';

class ReportService {
  Future<Map<String, dynamic>> fetchReport(String token, String projectId) async {
    final data = await ApiService.get('/projects/$projectId/report', token: token);
    if (data is Map<String, dynamic>) {
      return (data['report'] is Map<String, dynamic>)
          ? data['report'] as Map<String, dynamic>
          : data;
    }
    return <String, dynamic>{};
  }
}
