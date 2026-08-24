double _budgetDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

class Budget {
  const Budget({
    required this.totalBudget,
    required this.spent,
    required this.remaining,
  });

  final double totalBudget;
  final double spent;
  final double remaining;

  factory Budget.fromJson(Map<String, dynamic> json) {
    final total = _budgetDouble(json['totalBudget'] ?? json['total']);
    final spent = _budgetDouble(json['spent']);
    return Budget(
      totalBudget: total,
      spent: spent,
      remaining: _budgetDouble(json['remaining'] ?? (total - spent)),
    );
  }
}
