import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'screens/admin/staff_management_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/projects/project_detail_screen.dart';
import 'screens/projects/projects_list_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BuildTrackProApp());
}

class BuildTrackProApp extends StatelessWidget {
  const BuildTrackProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
      ],
      child: const _AppView(),
    );
  }
}

class _AppView extends StatelessWidget {
  const _AppView();

  GoRouter _router(AuthProvider auth) {
    return GoRouter(
      initialLocation: '/',
      refreshListenable: auth,
      redirect: (context, state) {
        final loggingIn = state.matchedLocation == '/login';
        if (!auth.isAuthenticated && !loggingIn) {
          return '/login';
        }
        if (auth.isAuthenticated && loggingIn) {
          return '/';
        }
        if (state.matchedLocation.startsWith('/admin') && !auth.isAdmin) {
          return '/';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/projects',
          builder: (context, state) => const ProjectsListScreen(),
        ),
        GoRoute(
          path: '/projects/:projectId',
          builder: (context, state) => ProjectDetailScreen(
            projectId: state.pathParameters['projectId']!,
          ),
        ),
        GoRoute(
          path: '/admin/staff',
          builder: (context, state) => const StaffManagementScreen(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0B5ED7),
      primary: const Color(0xFF0B5ED7),
      secondary: const Color(0xFF00897B),
    );

    if (!auth.isInitialized) {
      return MaterialApp(
        title: 'BuildTrack Pro',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: colorScheme,
        ),
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp.router(
      title: 'BuildTrack Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
        snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      routerConfig: _router(auth),
    );
  }
}
