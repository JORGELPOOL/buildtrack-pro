import '../models/attendance.dart';
import 'api_service.dart';

class AttendanceService {
  Future<List<Attendance>> fetchAttendance(String token, String projectId) async {
    final data = await ApiService.get('/projects/$projectId/attendance', token: token);
    final list = data is List
        ? data
        : (data is Map<String, dynamic> ? data['attendance'] as List? ?? const [] : const []);
    return list.whereType<Map<String, dynamic>>().map(Attendance.fromJson).toList();
  }

  Future<void> createAttendance(String token, String projectId, Map<String, dynamic> payload) async {
    await ApiService.post('/projects/$projectId/attendance', token: token, body: payload);
  }

  Future<void> updateAttendance(String token, String attendanceId, Map<String, dynamic> payload) async {
    await ApiService.put('/attendance/$attendanceId', token: token, body: payload);
  }
}
