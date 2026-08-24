import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'module_screen.dart';
import 'staff_screen.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onLogout;
  const DashboardScreen({super.key, required this.onLogout});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? user;
  int selected = 0;

  final modules = const [
    ('Dashboard', Icons.dashboard_rounded),
    ('Project Tracking', Icons.account_tree_rounded),
    ('Budget Management', Icons.account_balance_wallet_rounded),
    ('Worker Attendance', Icons.how_to_reg_rounded),
    ('Material Management', Icons.inventory_2_rounded),
    ('Progress Photos', Icons.photo_library_rounded),
    ('Client Reporting', Icons.summarize_rounded),
    ('Staff Accounts', Icons.manage_accounts_rounded),
  ];

  @override
  void initState() { super.initState(); AuthService().getUser().then((v) => setState(() => user = v)); }

  @override
  Widget build(BuildContext context) {
    final isAdmin = user?['role'] == 'admin';
    final visible = isAdmin ? modules : modules.where((m) => m.$1 != 'Staff Accounts').toList();
    if (selected >= visible.length) selected = 0;
    return Scaffold(
      body: Row(children: [
        Container(
          width: 250,
          color: const Color(0xFF173B57),
          child: Column(children: [
            const Padding(padding: EdgeInsets.fromLTRB(22, 28, 22, 22), child: Row(children: [Icon(Icons.apartment_rounded, color: Colors.white), SizedBox(width: 12), Text('BuildTrack Pro', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18))])),
            Expanded(child: ListView.builder(itemCount: visible.length, itemBuilder: (_, i) => ListTile(
              selected: selected == i, selectedTileColor: Colors.white12,
              leading: Icon(visible[i].$2, color: Colors.white),
              title: Text(visible[i].$1, style: const TextStyle(color: Colors.white)),
              onTap: () => setState(() => selected = i),
            ))),
            ListTile(leading: const Icon(Icons.logout, color: Colors.white), title: const Text('Sign out', style: TextStyle(color: Colors.white)), onTap: () async { await AuthService().logout(); widget.onLogout(); }),
            const SizedBox(height: 12),
          ]),
        ),
        Expanded(child: Column(children: [
          Container(height: 72, padding: const EdgeInsets.symmetric(horizontal: 28), color: Colors.white, child: Row(children: [
            Text(visible[selected].$1, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const Spacer(),
            const CircleAvatar(child: Icon(Icons.person)), const SizedBox(width: 10),
            Text(user?['name'] ?? 'Loading...'),
          ])),
          Expanded(child: selected == 0 ? const _HomeDashboard() : (visible[selected].$1 == 'Staff Accounts' ? const StaffScreen() : ModuleScreen(title: visible[selected].$1))),
        ]))
      ]),
    );
  }
}

class _HomeDashboard extends StatelessWidget {
  const _HomeDashboard();
  @override
  Widget build(BuildContext context) {
    final cards = [
      ('Active Projects','8',Icons.construction), ('Budget Used','GH¢ 428,500',Icons.payments), ('Workers Today','64',Icons.groups), ('Low Stock Items','5',Icons.warning_amber),
    ];
    return SingleChildScrollView(padding: const EdgeInsets.all(28), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Construction Operations Overview', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
      const SizedBox(height: 6), const Text('A quick view of your active projects and site operations.'),
      const SizedBox(height: 24), Wrap(spacing: 18, runSpacing: 18, children: cards.map((c) => SizedBox(width: 230, height: 130, child: Card(elevation: 0, child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(c.$3), const Spacer(), Text(c.$2, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), Text(c.$1)]))))).toList()),
      const SizedBox(height: 28),
      Card(elevation: 0, child: Padding(padding: const EdgeInsets.all(22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Recent Project Progress', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)), const SizedBox(height: 18),
        ...[('Adum Office Complex',.72),('Ahodwo Residence',.46),('Airport Road Retail Fit-out',.88)].map((p) => Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Row(children: [SizedBox(width: 220, child: Text(p.$1)), Expanded(child: LinearProgressIndicator(value: p.$2)), const SizedBox(width: 16), Text('${(p.$2*100).round()}%')]))),
      ])))
    ]));
  }
}
