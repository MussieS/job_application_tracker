import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'today/today_screen.dart';
import 'apps/applications_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.auth});

  final AuthService auth;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final uid = widget.auth.currentUser!.uid;

    final pages = [
      TodayScreen(uid: uid),
      ApplicationsScreen(uid: uid),
      _PlaceholderPage(title: 'Analytics (later)', icon: Icons.insights_outlined),
    ];

    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.today_outlined), label: 'Today'),
          NavigationDestination(icon: Icon(Icons.work_outline), label: 'Apps'),
          NavigationDestination(icon: Icon(Icons.insights_outlined), label: 'Analytics'),
        ],
      ),
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('We’ll build this screen in the next part.',
                style: TextStyle(color: Theme.of(context).hintColor)),
          ],
        ),
      ),
    );
  }
}
