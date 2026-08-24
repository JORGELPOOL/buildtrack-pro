import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/project.dart';
import '../providers/auth_provider.dart';
import '../services/project_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ProjectService _projectService = ProjectService();
  late Future<List<Project>> _projectsFuture;

  @override
  void initState() {
    super.initState();
    _projectsFuture = _loadProjects();
  }

  Future<List<Project>> _loadProjects() {
    final token = context.read<AuthProvider>().token;
    if (token == null || token.isEmpty) return Future.value(const []);
    return _projectService.fetchProjects(token);
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.teal;
      case 'completed':
        return Colors.green;
      case 'delayed':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BuildTrack Pro Dashboard')),
      drawer: const AppDrawer(currentRoute: '/'),
      body: FutureBuilder<List<Project>>(
        future: _projectsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          final projects = snapshot.data ?? const <Project>[];
          final activeCount = projects.where((p) => p.status.toLowerCase() == 'active').length;
          final completedCount = projects.where((p) => p.status.toLowerCase() == 'completed').length;
          final totalBudget = projects.fold<double>(0, (sum, p) => sum + p.budgetTotal);

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _projectsFuture = _loadProjects();
              });
              await _projectsFuture;
            },
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final count = width > 1100 ? 4 : width > 750 ? 2 : 1;
                    return GridView.count(
                      crossAxisCount: count,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 2.2,
                      children: [
                        StatCard(
                          title: 'Total Projects',
                          value: '${projects.length}',
                          icon: Icons.business_center_outlined,
                        ),
                        StatCard(
                          title: 'Active Projects',
                          value: '$activeCount',
                          icon: Icons.play_circle_outline,
                          color: Colors.teal,
                        ),
                        StatCard(
                          title: 'Completed',
                          value: '$completedCount',
                          icon: Icons.task_alt,
                          color: Colors.green,
                        ),
                        StatCard(
                          title: 'Budget Portfolio',
                          value: '\$${totalBudget.toStringAsFixed(0)}',
                          icon: Icons.account_balance_wallet_outlined,
                          color: Colors.blue,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Recent Projects', style: Theme.of(context).textTheme.titleLarge),
                            const Spacer(),
                            TextButton(
                              onPressed: () => context.go('/projects'),
                              child: const Text('View all'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (projects.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Center(child: Text('No projects found.')),
                          )
                        else
                          ...projects.take(5).map(
                            (project) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(project.name),
                              subtitle: Text(project.description.isEmpty ? 'No description' : project.description),
                              trailing: Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 12,
                                children: [
                                  Chip(
                                    label: Text(project.status),
                                    backgroundColor: _statusColor(project.status).withOpacity(0.12),
                                    side: BorderSide.none,
                                  ),
                                  const Icon(Icons.chevron_right),
                                ],
                              ),
                              onTap: () => context.go('/projects/${project.id}'),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
