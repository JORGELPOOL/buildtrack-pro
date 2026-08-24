double _expenseDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _expenseDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

class Expense {
  const Expense({
    required this.id,
    required this.description,
    required this.category,
    required this.amount,
    this.date,
  });

  final String id;
  final String description;
  final String category;
  final double amount;
  final DateTime? date;

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? 'General',
      amount: _expenseDouble(json['amount']),
      date: _expenseDate(json['date']),
    );
  }
}
