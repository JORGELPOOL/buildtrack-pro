double _materialDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

class MaterialItem {
  const MaterialItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.status,
  });

  final String id;
  final String name;
  final double quantity;
  final String unit;
  final String status;

  factory MaterialItem.fromJson(Map<String, dynamic> json) {
    return MaterialItem(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      quantity: _materialDouble(json['quantity']),
      unit: json['unit']?.toString() ?? 'pcs',
      status: json['status']?.toString() ?? 'Pending',
    );
  }
}
