import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/budget.dart';
import '../../models/expense.dart';
import '../../providers/auth_provider.dart';
import '../../services/budget_service.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key, required this.projectId});

  final String projectId;

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final BudgetService _budgetService = BudgetService();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  Budget? _budget;
  List<Expense> _expenses = const [];
  late Future<void> _loadFuture;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadFuture = _loadData();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _categoryController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final token = context.read<AuthProvider>().token;
    if (token == null || token.isEmpty) return;
    final results = await Future.wait<dynamic>([
      _budgetService.fetchBudget(token, widget.projectId),
      _budgetService.fetchExpenses(token, widget.projectId),
    ]);
    _budget = results[0] as Budget;
    _expenses = results[1] as List<Expense>;
  }

  Future<void> _addExpense() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (_descriptionController.text.trim().isEmpty ||
        _categoryController.text.trim().isEmpty ||
        amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter description, category, and valid amount.')),
      );
      return;
    }

    final token = context.read<AuthProvider>().token;
    if (token == null || token.isEmpty) return;

    setState(() => _submitting = true);
    try {
      await _budgetService.addExpense(token, widget.projectId, {
        'description': _descriptionController.text.trim(),
        'category': _categoryController.text.trim(),
        'amount': amount,
        'date': _selectedDate.toIso8601String(),
      });
      _descriptionController.clear();
      _categoryController.clear();
      _amountController.clear();
      _selectedDate = DateTime.now();
      setState(() {
        _loadFuture = _loadData();
      });
      await _loadFuture;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense added successfully.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: '\$');

    return FutureBuilder<void>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && _budget == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
        }

        final budget = _budget ?? const Budget(totalBudget: 0, spent: 0, remaining: 0);
        final progress = budget.totalBudget <= 0 ? 0.0 : (budget.spent / budget.totalBudget).clamp(0.0, 1.0).toDouble();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Budget Overview', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(value: progress),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _BudgetMetric(label: 'Total', value: currency.format(budget.totalBudget)),
                        _BudgetMetric(label: 'Spent', value: currency.format(budget.spent)),
                        _BudgetMetric(label: 'Remaining', value: currency.format(budget.remaining)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Add Expense', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: 240,
                          child: TextField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(labelText: 'Description'),
                          ),
                        ),
                        SizedBox(
                          width: 180,
                          child: TextField(
                            controller: _categoryController,
                            decoration: const InputDecoration(labelText: 'Category'),
                          ),
                        ),
                        SizedBox(
                          width: 140,
                          child: TextField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Amount'),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() => _selectedDate = picked);
                            }
                          },
                          icon: const Icon(Icons.calendar_today_outlined),
                          label: Text(DateFormat.yMMMd().format(_selectedDate)),
                        ),
                        FilledButton.icon(
                          onPressed: _submitting ? null : _addExpense,
                          icon: const Icon(Icons.add),
                          label: const Text('Save Expense'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Expense History', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    if (_expenses.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: Text('No expenses recorded yet.')),
                      )
                    else
                      ..._expenses.map(
                        (expense) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.receipt_long_outlined),
                          title: Text(expense.description),
                          subtitle: Text('${expense.category} • ${expense.date != null ? DateFormat.yMMMd().format(expense.date!) : 'No date'}'),
                          trailing: Text(currency.format(expense.amount)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BudgetMetric extends StatelessWidget {
  const _BudgetMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 140),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surfaceVariant,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 6),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
