double _projectDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _projectDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

class Project {
  const Project({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    this.startDate,
    this.endDate,
    this.budgetTotal = 0,
  });

  final String id;
  final String name;
  final String description;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;
  final double budgetTotal;

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Untitled Project',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Planned',
      startDate: _projectDate(json['startDate']),
      endDate: _projectDate(json['endDate']),
      budgetTotal: _projectDouble(json['budgetTotal'] ?? json['budget']),
    );
  }
}
