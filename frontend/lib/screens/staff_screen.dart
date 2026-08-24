import 'package:flutter/material.dart';
import '../services/api_service.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();

  String role = 'staff';
  String? message;

  Future<void> create() async {
    try {
      await ApiService().post('/users', {
        'name': name.text,
        'email': email.text,
        'password': password.text,
        'role': role,
      });

      setState(() {
        message = 'Staff account created successfully.';
      });
    } catch (e) {
      setState(() {
        message = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Staff User Accounts',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Administrators can create staff login credentials and assign roles.',
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    TextField(
                      controller: name,
                      decoration: const InputDecoration(
                        labelText: 'Full name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: email,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: password,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Temporary password',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: role,
                      decoration: const InputDecoration(
                        labelText: 'Role',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'staff',
                          child: Text('Staff'),
                        ),
                        DropdownMenuItem(
                          value: 'admin',
                          child: Text('Administrator'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            role = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 18),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: create,
                        icon: const Icon(Icons.person_add),
                        label: const Text('Create account'),
                      ),
                    ),
                    if (message != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(message!),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }
}
