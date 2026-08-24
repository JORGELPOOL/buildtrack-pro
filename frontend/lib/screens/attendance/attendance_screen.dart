import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/attendance.dart';
import '../../providers/auth_provider.dart';
import '../../services/attendance_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key, required this.projectId});

  final String projectId;

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  late Future<void> _loadFuture;
  List<Attendance> _records = const [];
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadFuture = _loadData();
  }

  Future<void> _loadData() async {
    final token = context.read<AuthProvider>().token;
    if (token == null || token.isEmpty) return;
    _records = await _attendanceService.fetchAttendance(token, widget.projectId);
  }

  Future<void> _showRecordDialog({Attendance? existing}) async {
    final nameController = TextEditingController(text: existing?.staffName ?? '');
    final checkInController = TextEditingController(text: existing?.checkIn ?? '');
    final checkOutController = TextEditingController(text: existing?.checkOut ?? '');
    var status = existing?.status ?? 'Present';
    var selectedDate = existing?.date ?? DateTime.now();
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(existing == null ? 'Add Attendance' : 'Edit Attendance'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: StatefulBuilder(
                builder: (context, setStateDialog) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Staff name'),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: status,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: const ['Present', 'Absent', 'Late', 'Half Day']
                            .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setStateDialog(() => status = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: Text(DateFormat.yMMMd().format(selectedDate))),
                          TextButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setStateDialog(() => selectedDate = picked);
                              }
                            },
                            child: const Text('Choose date'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: checkInController,
                        decoration: const InputDecoration(labelText: 'Check in (optional)'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: checkOutController,
                        decoration: const InputDecoration(labelText: 'Check out (optional)'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop(true);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (saved != true) return;
    final token = context.read<AuthProvider>().token;
    if (token == null || token.isEmpty) return;

    final payload = {
      'staffName': nameController.text.trim(),
      'status': status,
      'date': selectedDate.toIso8601String(),
      'checkIn': checkInController.text.trim(),
      'checkOut': checkOutController.text.trim(),
    };

    setState(() => _submitting = true);
    try {
      if (existing == null) {
        await _attendanceService.createAttendance(token, widget.projectId, payload);
      } else {
        await _attendanceService.updateAttendance(token, existing.id, payload);
      }
      setState(() {
        _loadFuture = _loadData();
      });
      await _loadFuture;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(existing == null ? 'Attendance added.' : 'Attendance updated.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && _records.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Text('Attendance Records', style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _submitting ? null : () => _showRecordDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Record'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Staff')),
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Check In')),
                    DataColumn(label: Text('Check Out')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: _records
                      .map(
                        (record) => DataRow(
                          cells: [
                            DataCell(Text(record.staffName)),
                            DataCell(Text(record.date != null ? DateFormat.yMMMd().format(record.date!) : '-')),
                            DataCell(Text(record.status)),
                            DataCell(Text(record.checkIn?.isNotEmpty == true ? record.checkIn! : '-')),
                            DataCell(Text(record.checkOut?.isNotEmpty == true ? record.checkOut! : '-')),
                            DataCell(
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: _submitting ? null : () => _showRecordDialog(existing: record),
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            if (_records.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Center(child: Text('No attendance records yet.')),
              ),
          ],
        );
      },
    );
  }
}
