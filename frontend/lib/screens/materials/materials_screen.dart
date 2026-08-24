import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/material_item.dart';
import '../../providers/auth_provider.dart';
import '../../services/material_service.dart';

class MaterialsScreen extends StatefulWidget {
  const MaterialsScreen({super.key, required this.projectId});

  final String projectId;

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  final MaterialService _materialService = MaterialService();
  late Future<void> _loadFuture;
  List<MaterialItem> _materials = const [];
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadFuture = _loadData();
  }

  Future<void> _loadData() async {
    final token = context.read<AuthProvider>().token;
    if (token == null || token.isEmpty) return;
    _materials = await _materialService.fetchMaterials(token, widget.projectId);
  }

  Future<void> _showMaterialDialog({MaterialItem? existing}) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final quantityController = TextEditingController(text: existing?.quantity.toString() ?? '');
    final unitController = TextEditingController(text: existing?.unit ?? 'pcs');
    var status = existing?.status ?? 'Pending';
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(existing == null ? 'Add Material' : 'Edit Material'),
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
                        decoration: const InputDecoration(labelText: 'Material name'),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: quantityController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Quantity'),
                        validator: (value) => double.tryParse(value ?? '') == null ? 'Enter a number' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: unitController,
                        decoration: const InputDecoration(labelText: 'Unit'),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: status,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: const ['Pending', 'Ordered', 'Delivered', 'Used']
                            .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setStateDialog(() => status = value);
                          }
                        },
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
      'name': nameController.text.trim(),
      'quantity': double.parse(quantityController.text.trim()),
      'unit': unitController.text.trim(),
      'status': status,
    };

    setState(() => _submitting = true);
    try {
      if (existing == null) {
        await _materialService.createMaterial(token, widget.projectId, payload);
      } else {
        await _materialService.updateMaterial(token, existing.id, payload);
      }
      setState(() {
        _loadFuture = _loadData();
      });
      await _loadFuture;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(existing == null ? 'Material added.' : 'Material updated.')),
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
        if (snapshot.connectionState == ConnectionState.waiting && _materials.isEmpty) {
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
                Text('Material Tracking', style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _submitting ? null : () => _showMaterialDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Material'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Material')),
                    DataColumn(label: Text('Quantity')),
                    DataColumn(label: Text('Unit')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: _materials
                      .map(
                        (item) => DataRow(
                          cells: [
                            DataCell(Text(item.name)),
                            DataCell(Text(item.quantity.toStringAsFixed(item.quantity == item.quantity.roundToDouble() ? 0 : 2))),
                            DataCell(Text(item.unit)),
                            DataCell(Text(item.status)),
                            DataCell(
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: _submitting ? null : () => _showMaterialDialog(existing: item),
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            if (_materials.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Center(child: Text('No materials added yet.')),
              ),
          ],
        );
      },
    );
  }
}
