import '../models/budget.dart';
import '../models/expense.dart';
import 'api_service.dart';

class BudgetService {
  Future<Budget> fetchBudget(String token, String projectId) async {
    final data = await ApiService.get('/projects/$projectId/budget', token: token);
    final json = data is Map<String, dynamic>
        ? ((data['budget'] is Map<String, dynamic>) ? data['budget'] as Map<String, dynamic> : data)
        : <String, dynamic>{};
    return Budget.fromJson(json);
  }

  Future<List<Expense>> fetchExpenses(String token, String projectId) async {
    final data = await ApiService.get('/projects/$projectId/expenses', token: token);
    final list = data is List
        ? data
        : (data is Map<String, dynamic> ? data['expenses'] as List? ?? const [] : const []);
    return list.whereType<Map<String, dynamic>>().map(Expense.fromJson).toList();
  }

  Future<void> addExpense(String token, String projectId, Map<String, dynamic> payload) async {
    await ApiService.post('/projects/$projectId/expenses', token: token, body: payload);
  }
}
