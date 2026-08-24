import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/project.dart';
import '../../providers/auth_provider.dart';
import '../../services/project_service.dart';
import '../../widgets/app_drawer.dart';

class ProjectsListScreen extends StatefulWidget {
  const ProjectsListScreen({super.key});

  @override
  State<ProjectsListScreen> createState() => _ProjectsListScreenState();
}

class _ProjectsListScreenState extends State<ProjectsListScreen> {
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
      appBar: AppBar(title: const Text('Projects')),
      drawer: const AppDrawer(currentRoute: '/projects'),
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
          if (projects.isEmpty) {
            return const Center(child: Text('No projects available.'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _projectsFuture = _loadProjects();
              });
              await _projectsFuture;
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: projects.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final project = projects[index];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(20),
                    title: Text(project.name, style: Theme.of(context).textTheme.titleMedium),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(project.description.isEmpty ? 'No description available.' : project.description),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Chip(
                          label: Text(project.status),
                          backgroundColor: _statusColor(project.status).withOpacity(0.12),
                          side: BorderSide.none,
                        ),
                        const SizedBox(height: 8),
                        const Text('View details'),
                      ],
                    ),
                    onTap: () => context.go('/projects/${project.id}'),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
