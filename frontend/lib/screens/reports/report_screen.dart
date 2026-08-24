import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/report_service.dart';
import '../../widgets/stat_card.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key, required this.projectId});

  final String projectId;

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final ReportService _reportService = ReportService();
  late Future<Map<String, dynamic>> _reportFuture;

  @override
  void initState() {
    super.initState();
    _reportFuture = _loadReport();
  }

  Future<Map<String, dynamic>> _loadReport() {
    final token = context.read<AuthProvider>().token;
    if (token == null || token.isEmpty) return Future.value(<String, dynamic>{});
    return _reportService.fetchReport(token, widget.projectId);
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _reportFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
        }

        final report = snapshot.data ?? const <String, dynamic>{};
        final statusBreakdown = Map<String, dynamic>.from(report['statusBreakdown'] as Map? ?? const {});
        final chartData = statusBreakdown.isNotEmpty
            ? statusBreakdown
            : {
                'Budget': report['budgetHealth'] ?? 0,
                'Attendance': report['attendanceRate'] ?? 0,
                'Materials': report['materialsReady'] ?? 0,
              };
        final metrics = chartData.entries.toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: 260,
                  child: StatCard(
                    title: 'Budget Health',
                    value: '${_toDouble(report['budgetHealth']).toStringAsFixed(0)}%',
                    icon: Icons.savings_outlined,
                    color: Colors.teal,
                  ),
                ),
                SizedBox(
                  width: 260,
                  child: StatCard(
                    title: 'Attendance Rate',
                    value: '${_toDouble(report['attendanceRate']).toStringAsFixed(0)}%',
                    icon: Icons.groups_outlined,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(
                  width: 260,
                  child: StatCard(
                    title: 'Materials Ready',
                    value: '${_toDouble(report['materialsReady']).toStringAsFixed(0)}%',
                    icon: Icons.inventory_2_outlined,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  height: 300,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 100.0,
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= metrics.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(metrics[index].key),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: [
                        for (var i = 0; i < metrics.length; i++)
                          BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: _toDouble(metrics[i].value).clamp(0.0, 100.0).toDouble(),
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(6),
                                width: 28,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
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
                    Text('Summary', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    Text(report['summary']?.toString() ?? 'No project summary provided by the API yet.'),
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
