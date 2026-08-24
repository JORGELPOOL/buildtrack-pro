import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.currentRoute,
  });

  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userInitial =
        auth.user?.name.isNotEmpty == true ? auth.user!.name[0].toUpperCase() : 'B';

    Widget navTile({
      required String title,
      required IconData icon,
      required String route,
    }) {
      final selected = currentRoute == route;
      return ListTile(
        leading: Icon(icon),
        title: Text(title),
        selected: selected,
        onTap: () {
          Navigator.of(context).pop();
          if (!selected) {
            context.go(route);
          }
        },
      );
    }

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(auth.user?.name ?? 'BuildTrack Pro'),
              accountEmail: Text(auth.user?.email ?? 'project@buildtrack.pro'),
              currentAccountPicture: CircleAvatar(
                child: Text(userInitial),
              ),
            ),
            navTile(title: 'Dashboard', icon: Icons.dashboard_outlined, route: '/'),
            navTile(title: 'Projects', icon: Icons.apartment_outlined, route: '/projects'),
            if (auth.isAdmin)
              navTile(
                title: 'Staff Management',
                icon: Icons.manage_accounts_outlined,
                route: '/admin/staff',
              ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                Navigator.of(context).pop();
                await context.read<AuthProvider>().logout();
                if (context.mounted) {
                  context.go('/login');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
