import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/application.dart';
import '../../services/firestore_service.dart';
import '../../utils/enums.dart';
import '../../viewmodels/applications_viewmodel.dart';
import '../../widgets/application_card.dart';
import 'add_edit_application_screen.dart';
import 'application_detail_screen.dart';

class ApplicationsScreen extends StatelessWidget {
  const ApplicationsScreen({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ApplicationsViewModel(FirestoreService()),
      child: _AppsBody(uid: uid),
    );
  }
}

class _AppsBody extends StatelessWidget {
  const _AppsBody({required this.uid});

  final String uid;

  Future<void> _addOrEdit(BuildContext context, ApplicationsViewModel vm, {Application? existing}) async {
    final result = await Navigator.of(context).push<Application>(
      MaterialPageRoute(
        builder: (_) => AddEditApplicationScreen(uid: uid, existing: existing),
      ),
    );

    if (result == null) return;

    if (existing == null) {
      await vm.createApp(result);
    } else {
      await vm.updateApp(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ApplicationsViewModel>();

    return StreamBuilder<List<Application>>(
      stream: vm.watchApps(uid),
      builder: (context, snap) {
        final all = snap.data ?? const [];
        final apps = vm.applyFilters(all);

        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search company or role...',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: vm.setSearch,
                ),
                const SizedBox(height: 10),
                _FilterRow(vm: vm),
                const SizedBox(height: 10),

                Expanded(
                  child: (snap.connectionState == ConnectionState.waiting)
                      ? const Center(child: CircularProgressIndicator())
                      : apps.isEmpty
                      ? _EmptyApps(onAdd: () => _addOrEdit(context, vm))
                      : vm.kanbanMode
                      ? _Kanban(apps: apps, onEdit: (a) => _addOrEdit(context, vm, existing: a), onDelete: vm.deleteApp)
                      : _List(apps: apps, onEdit: (a) => _addOrEdit(context, vm, existing: a), onDelete: vm.deleteApp),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.vm});
  final ApplicationsViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<AppStatus?>(
            value: vm.statusFilter,
            decoration: const InputDecoration(
              labelText: 'Status',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('All')),
              ...AppStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(enumToString(s)))),
            ],
            onChanged: vm.setStatusFilter,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DropdownButtonFormField<Priority?>(
            value: vm.priorityFilter,
            decoration: const InputDecoration(
              labelText: 'Priority',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('All')),
              ...Priority.values.map((p) => DropdownMenuItem(value: p, child: Text(enumToString(p)))),
            ],
            onChanged: vm.setPriorityFilter,
          ),
        ),
      ],
    );
  }
}

class _List extends StatelessWidget {
  const _List({required this.apps, required this.onEdit, required this.onDelete});

  final List<Application> apps;
  final void Function(Application) onEdit;
  final Future<void> Function(String) onDelete;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: apps.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final a = apps[i];
        return ApplicationCard(
          app: a,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ApplicationDetailScreen(app: a)),
            );
          },
          onDelete: () async {
            final ok = await _confirmDelete(context);
            if (ok) await onDelete(a.id);
          },
        );
      },
    );
  }
}

class _Kanban extends StatelessWidget {
  const _Kanban({required this.apps, required this.onEdit, required this.onDelete});

  final List<Application> apps;
  final void Function(Application) onEdit;
  final Future<void> Function(String) onDelete;

  List<Application> _by(AppStatus s) => apps.where((a) => a.status == s).toList();

  @override
  Widget build(BuildContext context) {
    final columns = <(String, AppStatus)>[
      ('Applied', AppStatus.applied),
      ('OA', AppStatus.oa),
      ('Interview', AppStatus.interview),
      ('Offer', AppStatus.offer),
      ('Rejected', AppStatus.rejected),
      ('Archived', AppStatus.archived),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: columns.map((c) {
          final title = c.$1;
          final status = c.$2;
          final list = _by(status);

          return Container(
            width: 320,
            margin: const EdgeInsets.only(right: 12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$title (${list.length})',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    Expanded(
                      child: list.isEmpty
                          ? Center(child: Text('No items', style: TextStyle(color: Theme.of(context).hintColor)))
                          : ListView.separated(
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final a = list[i];
                          return ApplicationCard(
                            app: a,
                            onTap: () => onEdit(a),
                            onDelete: () async {
                              final ok = await _confirmDelete(context);
                              if (ok) await onDelete(a.id);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _EmptyApps extends StatelessWidget {
  const _EmptyApps({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.work_outline, size: 60),
            const SizedBox(height: 12),
            const Text('No applications yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('Add your first application and start creating follow-ups.',
                textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).hintColor)),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add application'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> _confirmDelete(BuildContext context) async {
  final res = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete application?'),
      content: const Text('This will also delete related tasks/contacts/docs.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
      ],
    ),
  );
  return res ?? false;
}
