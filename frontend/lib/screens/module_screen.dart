import 'package:flutter/material.dart';

class ModuleScreen extends StatelessWidget {
  final String title;
  const ModuleScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final config = {
      'Project Tracking': ('Track milestones, deadlines, status and project completion.', ['Adum Office Complex','Ahodwo Residence','Airport Road Retail Fit-out']),
      'Budget Management': ('Create project budgets, record expenses and monitor variance.', ['Concrete works – GH¢ 82,000','Electrical – GH¢ 35,500','Finishing – GH¢ 64,000']),
      'Worker Attendance': ('Check workers in/out and review daily attendance.', ['Kwame Mensah – Present','Ama Boateng – Present','Kofi Asare – Absent']),
      'Material Management': ('Manage stock received, issued, remaining quantities and reorder levels.', ['Cement – 240 bags','Iron rods – 185 lengths','Blocks – 1,420 units']),
      'Progress Photos': ('Upload site photos with project, date, location and notes.', ['Foundation completed','First-floor slab','Electrical conduit installation']),
      'Client Reporting': ('Generate clear progress summaries for clients and stakeholders.', ['Weekly progress report','Budget vs actual report','Site activity summary']),
    }[title]!;
    return SingleChildScrollView(padding: const EdgeInsets.all(28), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)), const SizedBox(height: 6), Text(config.$1), const SizedBox(height: 22),
      Align(alignment: Alignment.centerRight, child: FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.add), label: Text('Add ${title.replaceAll(' Management','').replaceAll(' Tracking','')}'))), const SizedBox(height: 16),
      Card(elevation: 0, child: ListView.separated(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: config.$2.length, separatorBuilder: (_,__) => const Divider(height: 1), itemBuilder: (_,i) => ListTile(leading: CircleAvatar(child: Text('${i+1}')), title: Text(config.$2[i]), subtitle: const Text('Sample record — connect to API for live data'), trailing: const Icon(Icons.chevron_right)))),
    ]));
  }
}
