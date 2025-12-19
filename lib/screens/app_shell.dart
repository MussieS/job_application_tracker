import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/export_service.dart';
import '../models/application.dart';
import '../models/task_item.dart';

import 'today/today_screen.dart';
import 'apps/applications_screen.dart';
import 'analytics/analytics_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      AnalyticsScreen(uid: uid),
    ];

    return MultiProvider(
      providers: [
        Provider(create: (_) => FirestoreService()),
        Provider(create: (_) => ExportService()),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Job Tracker'),
          actions: [
            PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'logout') {
                  await widget.auth.signOut();
                } else if (v == 'export') {
                  await _exportAndShare(context, uid);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'export', child: Text('Export CSV')),
                PopupMenuItem(value: 'logout', child: Text('Logout')),
              ],
            ),
          ],
        ),
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
      ),
    );
  }

  Future<void> _exportAndShare(BuildContext context, String uid) async {
    final fs = context.read<FirestoreService>();
    final exporter = context.read<ExportService>();

    // One-time fetch for export (not streams)
    final apps = await fs.watchApplications(uid).first;
    final tasks = await _fetchAllTasks(uid);

    final file = await exporter.exportCsv(apps: apps, tasks: tasks);

    if (!mounted) return;
    await Share.shareXFiles([XFile(file.path)], text: 'Job Tracker export');
  }

  Future<List<TaskItem>> _fetchAllTasks(String uid) async {
    final db = context.read<FirestoreService>();
    // FirestoreService doesn't have a "watch all tasks" method yet; quick direct query here:
    // (We keep it here to avoid expanding service too much.)
    final snap = await FirebaseFirestore.instance
        .collection('tasks')
        .where('uid', isEqualTo: uid)
        .get();

    return snap.docs.map((d) => TaskItem.fromDoc(d)).toList();
  }
}
