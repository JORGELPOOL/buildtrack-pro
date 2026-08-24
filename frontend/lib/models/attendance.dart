DateTime? _attendanceDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

class Attendance {
  const Attendance({
    required this.id,
    required this.staffName,
    required this.status,
    this.date,
    this.checkIn,
    this.checkOut,
  });

  final String id;
  final String staffName;
  final String status;
  final DateTime? date;
  final String? checkIn;
  final String? checkOut;

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      staffName: json['staffName']?.toString() ?? json['name']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Present',
      date: _attendanceDate(json['date']),
      checkIn: json['checkIn']?.toString(),
      checkOut: json['checkOut']?.toString(),
    );
  }
}
