import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/project.dart';
import '../../providers/auth_provider.dart';
import '../../services/project_service.dart';
import '../../widgets/app_drawer.dart';
import '../attendance/attendance_screen.dart';
import '../budget/budget_screen.dart';
import '../materials/materials_screen.dart';
import '../photos/photos_screen.dart';
import '../reports/report_screen.dart';

class ProjectDetailScreen extends StatefulWidget {
  const ProjectDetailScreen({super.key, required this.projectId});

  final String projectId;

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final ProjectService _projectService = ProjectService();
  late Future<Project> _projectFuture;

  @override
  void initState() {
    super.initState();
    _projectFuture = _loadProject();
  }

  Future<Project> _loadProject() {
    final token = context.read<AuthProvider>().token;
    if (token == null || token.isEmpty) {
      return Future.value(
        const Project(id: '', name: 'Project', description: '', status: 'Unknown'),
      );
    }
    return _projectService.fetchProject(token, widget.projectId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Project>(
      future: _projectFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text(snapshot.error.toString())));
        }

        final project = snapshot.data ??
            const Project(id: '', name: 'Project', description: '', status: 'Unknown');

        return DefaultTabController(
          length: 6,
          child: Scaffold(
            appBar: AppBar(
              title: Text(project.name),
              bottom: const TabBar(
                isScrollable: true,
                tabs: [
                  Tab(text: 'Overview'),
                  Tab(text: 'Budget'),
                  Tab(text: 'Attendance'),
                  Tab(text: 'Materials'),
                  Tab(text: 'Photos'),
                  Tab(text: 'Report'),
                ],
              ),
            ),
            drawer: const AppDrawer(currentRoute: '/projects'),
            body: TabBarView(
              children: [
                _ProjectOverviewTab(project: project),
                BudgetScreen(projectId: widget.projectId),
                AttendanceScreen(projectId: widget.projectId),
                MaterialsScreen(projectId: widget.projectId),
                PhotosScreen(projectId: widget.projectId),
                ReportScreen(projectId: widget.projectId),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProjectOverviewTab extends StatelessWidget {
  const _ProjectOverviewTab({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(project.name, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(project.description.isEmpty ? 'No project description provided.' : project.description),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _OverviewItem(label: 'Status', value: project.status),
                    _OverviewItem(
                      label: 'Start Date',
                      value: project.startDate != null ? dateFormat.format(project.startDate!) : 'Not set',
                    ),
                    _OverviewItem(
                      label: 'End Date',
                      value: project.endDate != null ? dateFormat.format(project.endDate!) : 'Not set',
                    ),
                    _OverviewItem(
                      label: 'Budget',
                      value: '\$${project.budgetTotal.toStringAsFixed(0)}',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OverviewItem extends StatelessWidget {
  const _OverviewItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
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
