import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ModuleScreen extends StatefulWidget {
  final String title;

  const ModuleScreen({super.key, required this.title});

  @override
  State<ModuleScreen> createState() => _ModuleScreenState();
}

class _ModuleScreenState extends State<ModuleScreen> {
  final ApiService _api = ApiService();

  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;

  String get _path => switch (widget.title) {
        'Project Tracking' => '/projects',
        'Budget Management' => '/budgets',
        'Worker Attendance' => '/attendance',
        'Material Management' => '/materials',
        'Progress Photos' => '/photos',
        'Client Reporting' => '/reports',
        _ => '',
      };

  String get _description => switch (widget.title) {
        'Project Tracking' =>
          'Track milestones, deadlines, status and project completion.',
        'Budget Management' =>
          'Create project budgets, record expenses and monitor variance.',
        'Worker Attendance' =>
          'Check workers in/out and review daily attendance.',
        'Material Management' =>
          'Manage stock received, issued, remaining quantities and reorder levels.',
        'Progress Photos' =>
          'Record site photos with project, date, location and notes.',
        'Client Reporting' =>
          'Generate clear progress summaries for clients and stakeholders.',
        _ => '',
      };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_path.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _api.getList(_path);

      if (mounted) {
        setState(() {
          _items = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  Future<void> _add() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _AddDialog(title: widget.title),
    );

    if (result == null) return;

    try {
      await _api.post(_path, result);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Record added successfully.')),
      );

      await _load();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  String _titleFor(Map<String, dynamic> item) {
    switch (widget.title) {
      case 'Project Tracking':
        return '${item['name'] ?? 'Project'}';

      case 'Budget Management':
        return '${item['category'] ?? 'Budget'} – GH¢ ${item['budget_amount'] ?? 0}';

      case 'Worker Attendance':
        return '${item['worker_name'] ?? 'Worker'} – ${item['status'] ?? ''}';

      case 'Material Management':
        return '${item['name'] ?? 'Material'} – ${item['quantity_received'] ?? 0} ${item['unit'] ?? ''}';

      case 'Progress Photos':
        return item['caption']?.toString().isNotEmpty == true
            ? item['caption'].toString()
            : 'Progress photo';

      case 'Client Reporting':
        return item['title'] ?? 'Client report';

      default:
        return 'Record';
    }
  }

  String _subtitleFor(Map<String, dynamic> item) {
    switch (widget.title) {
      case 'Project Tracking':
        return '${item['client_name'] ?? 'No client'} • ${item['status'] ?? 'Planning'} • ${item['progress'] ?? 0}%';

      case 'Budget Management':
        return 'Project #${item['project_id'] ?? '-'} • Actual: GH¢ ${item['actual_amount'] ?? 0}';

      case 'Worker Attendance':
        return 'Project #${item['project_id'] ?? '-'} • ${item['attendance_date'] ?? ''}';

      case 'Material Management':
        final received = num.tryParse('${item['quantity_received'] ?? 0}') ?? 0;
        final used = num.tryParse('${item['quantity_used'] ?? 0}') ?? 0;

        return 'Project #${item['project_id'] ?? '-'} • Remaining: ${received - used} ${item['unit'] ?? ''}';

      case 'Progress Photos':
        return 'Project #${item['project_id'] ?? '-'} • ${item['photo_url'] ?? ''}';

      case 'Client Reporting':
        return 'Project #${item['project_id'] ?? '-'} • ${item['report_date'] ?? ''}';

      default:
        return '';
    }
  }

  String _addLabel() => switch (widget.title) {
        'Project Tracking' => 'Add Project',
        'Budget Management' => 'Add Budget',
        'Worker Attendance' => 'Add Attendance',
        'Material Management' => 'Add Material',
        'Progress Photos' => 'Add Progress Photo',
        'Client Reporting' => 'Add Client Report',
        _ => 'Add Record',
      };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(_description),
          const SizedBox(height: 22),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _add,
              icon: const Icon(Icons.add),
              label: Text(_addLabel()),
            ),
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_error != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_error!)),
                    TextButton(
                      onPressed: _load,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (_items.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No ${widget.title.toLowerCase()} records yet. '
                    'Click "${_addLabel()}" to create one.',
                  ),
                ),
              ),
            )
          else
            Card(
              elevation: 0,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final item = Map<String, dynamic>.from(_items[i] as Map);

                  return ListTile(
                    leading: CircleAvatar(
                      child: Text('${i + 1}'),
                    ),
                    title: Text(_titleFor(item)),
                    subtitle: Text(_subtitleFor(item)),
                    trailing: const Icon(Icons.chevron_right),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _AddDialog extends StatefulWidget {
  final String title;

  const _AddDialog({required this.title});

  @override
  State<_AddDialog> createState() => _AddDialogState();
}

class _AddDialogState extends State<_AddDialog> {
  final ApiService _api = ApiService();

  final Map<String, TextEditingController> _controllers = {};

  List<Map<String, dynamic>> _projects = [];
  bool _loadingProjects = false;
  String? _projectError;
  int? _selectedProjectId;

  String _status = 'Planning';
  String _attendanceStatus = 'Present';

  bool get _needsProject => widget.title != 'Project Tracking';

  @override
  void initState() {
    super.initState();

    if (_needsProject) {
      _loadProjects();
    }
  }

  Future<void> _loadProjects() async {
    setState(() {
      _loadingProjects = true;
      _projectError = null;
    });

    try {
      final data = await _api.getList('/projects');

      final projects = data
          .map(
            (item) => Map<String, dynamic>.from(item as Map),
          )
          .where((project) => project['id'] != null)
          .toList();

      if (!mounted) return;

      setState(() {
        _projects = projects;
        _loadingProjects = false;

        if (_projects.isNotEmpty) {
          _selectedProjectId = int.tryParse('${_projects.first['id']}');
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingProjects = false;
        _projectError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  TextEditingController _c(String key) {
    return _controllers.putIfAbsent(
      key,
      () => TextEditingController(),
    );
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  InputDecoration _dec(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    );
  }

  Widget _field(
    String key,
    String label, {
    bool number = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: _c(key),
        keyboardType: number
            ? const TextInputType.numberWithOptions(
                decimal: true,
              )
            : null,
        decoration: _dec(label),
      ),
    );
  }

  Widget _projectSelector() {
    if (_loadingProjects) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (_projectError != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Unable to load projects: $_projectError',
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _loadProjects,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_projects.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: Text(
          'No projects exist yet. Create a project first.',
          style: TextStyle(color: Colors.orange),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<int>(
        initialValue: _selectedProjectId,
        isExpanded: true,
        decoration: _dec('Project'),
        items: _projects
            .map((project) {
              final id = int.tryParse('${project['id']}');
              final name = '${project['name'] ?? 'Unnamed project'}';

              return DropdownMenuItem<int>(
                value: id,
                child: Text(
                  '#$id — $name',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            })
            .where((item) => item.value != null)
            .toList(),
        onChanged: (value) {
          setState(() {
            _selectedProjectId = value;
          });
        },
      ),
    );
  }

  Map<String, dynamic>? _buildBody() {
    switch (widget.title) {
      case 'Project Tracking':
        if (_c('name').text.trim().isEmpty) {
          return null;
        }

        return {
          'name': _c('name').text.trim(),
          'client_name': _c('client_name').text.trim(),
          'location': _c('location').text.trim(),
          'status': _status,
          'progress': num.tryParse(_c('progress').text) ?? 0,
          'start_date': _c('start_date').text.trim().isEmpty
              ? null
              : _c('start_date').text.trim(),
          'end_date': _c('end_date').text.trim().isEmpty
              ? null
              : _c('end_date').text.trim(),
        };

      case 'Budget Management':
        if (_selectedProjectId == null || _c('category').text.trim().isEmpty) {
          return null;
        }

        return {
          'project_id': _selectedProjectId,
          'category': _c('category').text.trim(),
          'budget_amount': num.tryParse(_c('budget_amount').text) ?? 0,
          'actual_amount': num.tryParse(_c('actual_amount').text) ?? 0,
        };

      case 'Worker Attendance':
        if (_selectedProjectId == null ||
            _c('worker_name').text.trim().isEmpty) {
          return null;
        }

        return {
          'project_id': _selectedProjectId,
          'worker_name': _c('worker_name').text.trim(),
          'attendance_date': _c('attendance_date').text.trim().isEmpty
              ? null
              : _c('attendance_date').text.trim(),
          'status': _attendanceStatus,
          'check_in': _c('check_in').text.trim().isEmpty
              ? null
              : _c('check_in').text.trim(),
          'check_out': _c('check_out').text.trim().isEmpty
              ? null
              : _c('check_out').text.trim(),
        };

      case 'Material Management':
        if (_selectedProjectId == null || _c('name').text.trim().isEmpty) {
          return null;
        }

        return {
          'project_id': _selectedProjectId,
          'name': _c('name').text.trim(),
          'unit': _c('unit').text.trim(),
          'quantity_received': num.tryParse(_c('quantity_received').text) ?? 0,
          'quantity_used': num.tryParse(_c('quantity_used').text) ?? 0,
          'reorder_level': num.tryParse(_c('reorder_level').text) ?? 0,
        };

      case 'Progress Photos':
        if (_selectedProjectId == null || _c('photo_url').text.trim().isEmpty) {
          return null;
        }

        return {
          'project_id': _selectedProjectId,
          'photo_url': _c('photo_url').text.trim(),
          'caption': _c('caption').text.trim(),
          'taken_at': _c('taken_at').text.trim().isEmpty
              ? null
              : _c('taken_at').text.trim(),
        };

      case 'Client Reporting':
        if (_selectedProjectId == null || _c('title').text.trim().isEmpty) {
          return null;
        }

        return {
          'project_id': _selectedProjectId,
          'title': _c('title').text.trim(),
          'summary': _c('summary').text.trim(),
          'report_date': _c('report_date').text.trim().isEmpty
              ? null
              : _c('report_date').text.trim(),
        };

      default:
        return null;
    }
  }

  List<Widget> _fields() {
    switch (widget.title) {
      case 'Project Tracking':
        return [
          _field('name', 'Project name'),
          _field('client_name', 'Client name'),
          _field('location', 'Location'),
          DropdownButtonFormField<String>(
            initialValue: _status,
            decoration: _dec('Status'),
            items: const [
              DropdownMenuItem(
                value: 'Planning',
                child: Text('Planning'),
              ),
              DropdownMenuItem(
                value: 'In Progress',
                child: Text('In Progress'),
              ),
              DropdownMenuItem(
                value: 'On Hold',
                child: Text('On Hold'),
              ),
              DropdownMenuItem(
                value: 'Completed',
                child: Text('Completed'),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _status = value ?? 'Planning';
              });
            },
          ),
          const SizedBox(height: 12),
          _field(
            'progress',
            'Progress (%)',
            number: true,
          ),
          _field(
            'start_date',
            'Start date (YYYY-MM-DD)',
          ),
          _field(
            'end_date',
            'End date (YYYY-MM-DD)',
          ),
        ];

      case 'Budget Management':
        return [
          _projectSelector(),
          _field('category', 'Budget category'),
          _field(
            'budget_amount',
            'Budget amount (GH¢)',
            number: true,
          ),
          _field(
            'actual_amount',
            'Actual amount (GH¢)',
            number: true,
          ),
        ];

      case 'Worker Attendance':
        return [
          _projectSelector(),
          _field('worker_name', 'Worker name'),
          _field(
            'attendance_date',
            'Date (YYYY-MM-DD)',
          ),
          DropdownButtonFormField<String>(
            initialValue: _attendanceStatus,
            decoration: _dec('Status'),
            items: const [
              DropdownMenuItem(
                value: 'Present',
                child: Text('Present'),
              ),
              DropdownMenuItem(
                value: 'Absent',
                child: Text('Absent'),
              ),
              DropdownMenuItem(
                value: 'Late',
                child: Text('Late'),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _attendanceStatus = value ?? 'Present';
              });
            },
          ),
          const SizedBox(height: 12),
          _field(
            'check_in',
            'Check-in (HH:MM)',
          ),
          _field(
            'check_out',
            'Check-out (HH:MM)',
          ),
        ];

      case 'Material Management':
        return [
          _projectSelector(),
          _field('name', 'Material name'),
          _field(
            'unit',
            'Unit (bags, lengths, units...)',
          ),
          _field(
            'quantity_received',
            'Quantity received',
            number: true,
          ),
          _field(
            'quantity_used',
            'Quantity used',
            number: true,
          ),
          _field(
            'reorder_level',
            'Reorder level',
            number: true,
          ),
        ];

      case 'Progress Photos':
        return [
          _projectSelector(),
          _field('photo_url', 'Photo URL'),
          _field('caption', 'Caption / notes'),
          _field(
            'taken_at',
            'Date/time (ISO format, optional)',
          ),
        ];

      case 'Client Reporting':
        return [
          _projectSelector(),
          _field('title', 'Report title'),
          _field('summary', 'Summary'),
          _field(
            'report_date',
            'Report date (YYYY-MM-DD)',
          ),
        ];

      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSave = !_needsProject ||
        (!_loadingProjects && _projectError == null && _projects.isNotEmpty);

    return AlertDialog(
      title: Text('Add ${widget.title}'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _fields(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: canSave
              ? () {
                  final body = _buildBody();

                  if (body == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please complete the required fields.',
                        ),
                      ),
                    );
                    return;
                  }

                  Navigator.pop(context, body);
                }
              : null,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
