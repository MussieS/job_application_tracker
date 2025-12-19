import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../screens/app_shell.dart';
import '../screens/auth/login_screen.dart';
import '../theme/theme_controller.dart';
import '../theme/app_theme.dart';

class JobTrackerApp extends StatelessWidget {
  const JobTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>();

    return Provider(
      create: (_) => AuthService(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Job Tracker',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: theme.mode, // ✅ controlled by ThemeController
        home: const _AuthGate(),
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();

    return StreamBuilder(
      stream: auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return LoginScreen(auth: auth);
        }

        return AppShell(auth: auth);
      },
    );
  }
}
