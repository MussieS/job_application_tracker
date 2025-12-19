import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/application.dart';
import '../../models/contact.dart';
import '../../models/doc_ref.dart';
import '../../models/task_item.dart';
import '../../services/firestore_service.dart';
import '../../utils/date_utils.dart';
import '../../utils/enums.dart';
import '../../utils/launch.dart';
import '../../widgets/application_card.dart'; // optional, not required
import '../../widgets/task_tile.dart';



class ApplicationDetailScreen extends StatelessWidget {
  const ApplicationDetailScreen({super.key, required this.app});

  final Application app;

  @override
  Widget build(BuildContext context) {
    return Provider(
      create: (_) => FirestoreService(),
      child: _DetailBody(app: app),
    );
  }
}

class _DetailBody extends StatefulWidget {
  const _DetailBody({required this.app});
  final Application app;

  @override
  State<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends State<_DetailBody> with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    final a = widget.app;

    return Scaffold(
      appBar: AppBar(
        title: Text('${a.companyName}'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Tasks'),
            Tab(text: 'Contacts'),
            Tab(text: 'Docs'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _OverviewTab(app: a),
          _TasksTab(app: a, fs: fs),
          _ContactsTab(app: a, fs: fs),
          _DocsTab(app: a, fs: fs),
        ],
      ),
    );
  }
}

/* ---------------------------
   Overview
----------------------------*/
class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.app});
  final Application app;

  @override
  Widget build(BuildContext context) {
    final applied = DateFormat('MMM d, yyyy').format(app.dateApplied);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(app.companyName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(app.roleTitle, style: TextStyle(color: Theme.of(context).hintColor)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(label: Text('Status: ${enumToString(app.status)}')),
                    Chip(label: Text('Priority: ${enumToString(app.priority)}')),
                    Chip(label: Text('Applied: $applied')),
                    if ((app.location ?? '').trim().isNotEmpty) Chip(label: Text(app.location!)),
                    if ((app.source ?? '').trim().isNotEmpty) Chip(label: Text('Source: ${app.source!}')),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        if ((app.jobUrl ?? '').trim().isNotEmpty)
          FilledButton.icon(
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open job link'),
            onPressed: () async {
              final ok = await launchUrlStringSafe(app.jobUrl!);
              if (!ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not open link')),
                );
              }
            },
          ),

        const SizedBox(height: 12),
        if ((app.notes ?? '').trim().isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Notes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(app.notes!),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/* ---------------------------
   Tasks
----------------------------*/
class _TasksTab extends StatelessWidget {
  const _TasksTab({required this.app, required this.fs});
  final Application app;
  final FirestoreService fs;

  Future<void> _addTaskDialog(BuildContext context) async {
    final titleCtrl = TextEditingController();
    TaskType type = TaskType.custom;
    DateTime dueAt = DateTime.now().add(const Duration(hours: 2));

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add task'),
        content: StatefulBuilder(
          builder: (ctx, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<TaskType>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                  items: TaskType.values
                      .map((t) => DropdownMenuItem(value: t, child: Text(enumToString(t))))
                      .toList(),
                  onChanged: (v) => setState(() => type = v ?? TaskType.custom),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.event),
                        label: Text(DateFormat('MMM d').format(dueAt)),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            initialDate: dueAt,
                          );
                          if (picked == null) return;
                          setState(() => dueAt = DateTime(picked.year, picked.month, picked.day, dueAt.hour, dueAt.minute));
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.schedule),
                        label: Text(DateFormat('h:mm a').format(dueAt)),
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: ctx,
                            initialTime: TimeOfDay.fromDateTime(dueAt),
                          );
                          if (picked == null) return;
                          setState(() => dueAt = DateTime(dueAt.year, dueAt.month, dueAt.day, picked.hour, picked.minute));
                        },
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final title = titleCtrl.text.trim();
              if (title.isEmpty) return;

              final task = TaskItem(
                id: '',
                uid: app.uid,
                appId: app.id,
                type: type,
                title: title,
                dueAt: dueAt,
                done: false,
                createdAt: DateTime.now(),
                notes: null,
              );

              await fs.createTask(task);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _oneTapFollowUp(BuildContext context) async {
    final due = DateUtilsX.addDays(DateUtilsX.startOfDay(DateTime.now()), 7);
    final dueAt = DateTime(due.year, due.month, due.day, 10, 0);

    await fs.createFollowUpTask(
      uid: app.uid,
      appId: app.id,
      dueAt: dueAt,
      companyName: app.companyName,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Follow-up task created (7 days)')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TaskItem>>(
      stream: fs.watchTasksForApp(uid: app.uid, appId: app.id, includeDone: true),
      builder: (context, snap) {
        final tasks = snap.data ?? const [];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add task'),
                    onPressed: () => _addTaskDialog(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.tonalIcon(
                    icon: const Icon(Icons.mark_email_unread_outlined),
                    label: const Text('Follow-up (7d)'),
                    onPressed: () => _oneTapFollowUp(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (snap.connectionState == ConnectionState.waiting)
              const Center(child: Padding(padding: EdgeInsets.only(top: 24), child: CircularProgressIndicator())),

            if (tasks.isEmpty && snap.connectionState != ConnectionState.waiting)
              Padding(
                padding: const EdgeInsets.only(top: 30),
                child: Center(
                  child: Text('No tasks yet.', style: TextStyle(color: Theme.of(context).hintColor)),
                ),
              ),

            ...tasks.map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TaskTile(
                task: t,
                onToggleDone: () => fs.markTaskDone(t.id, !t.done),
                onReschedule: () {}, // keep simple here; Today screen already has reschedule
              ),
            )),
          ],
        );
      },
    );
  }
}

/* ---------------------------
   Contacts
----------------------------*/
class _ContactsTab extends StatelessWidget {
  const _ContactsTab({required this.app, required this.fs});
  final Application app;
  final FirestoreService fs;

  Future<void> _addContactDialog(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final roleCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final linkedinCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add contact'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: roleCtrl, decoration: const InputDecoration(labelText: 'Role (optional)', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email (optional)', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: linkedinCtrl, decoration: const InputDecoration(labelText: 'LinkedIn URL (optional)', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: notesCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Notes (optional)', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;

              final c = Contact(
                id: '',
                uid: app.uid,
                appId: app.id,
                name: name,
                role: roleCtrl.text.trim().isEmpty ? null : roleCtrl.text.trim(),
                email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                linkedinUrl: linkedinCtrl.text.trim().isEmpty ? null : linkedinCtrl.text.trim(),
                notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                createdAt: DateTime.now(),
              );

              await fs.createContact(c);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Contact>>(
      stream: fs.watchContactsForApp(uid: app.uid, appId: app.id),
      builder: (context, snap) {
        final contacts = snap.data ?? const [];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FilledButton.icon(
              icon: const Icon(Icons.person_add),
              label: const Text('Add contact'),
              onPressed: () => _addContactDialog(context),
            ),
            const SizedBox(height: 12),

            if (contacts.isEmpty && snap.connectionState != ConnectionState.waiting)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Center(child: Text('No contacts yet.', style: TextStyle(color: Theme.of(context).hintColor))),
              ),

            ...contacts.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ListTile(
                  title: Text(c.name),
                  subtitle: Text([
                    if ((c.role ?? '').trim().isNotEmpty) c.role!,
                    if ((c.email ?? '').trim().isNotEmpty) c.email!,
                  ].join(' • ')),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if ((c.linkedinUrl ?? '').trim().isNotEmpty)
                        IconButton(
                          tooltip: 'Open LinkedIn',
                          icon: const Icon(Icons.open_in_new),
                          onPressed: () async {
                            final ok = await launchUrlStringSafe(c.linkedinUrl!);
                            if (!ok && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Could not open LinkedIn link')),
                              );
                            }
                          },
                        ),
                      IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => fs.deleteContact(c.id),
                      ),
                    ],
                  ),
                ),
              ),
            )),
          ],
        );
      },
    );
  }
}

/* ---------------------------
   Docs
----------------------------*/
class _DocsTab extends StatelessWidget {
  const _DocsTab({required this.app, required this.fs});
  final Application app;
  final FirestoreService fs;

  Future<void> _addDocDialog(BuildContext context) async {
    String type = 'resume';
    final labelCtrl = TextEditingController();
    final urlCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add document'),
        content: StatefulBuilder(
          builder: (ctx, setState) => SingleChildScrollView(
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'resume', child: Text('resume')),
                    DropdownMenuItem(value: 'cover', child: Text('cover')),
                  ],
                  onChanged: (v) => setState(() => type = v ?? 'resume'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: labelCtrl,
                  decoration: const InputDecoration(labelText: 'Label (e.g., Resume v3)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: urlCtrl,
                  decoration: const InputDecoration(labelText: 'Link (optional)', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final label = labelCtrl.text.trim();
              if (label.isEmpty) return;

              final d = DocRef(
                id: '',
                uid: app.uid,
                appId: app.id,
                type: type,
                label: label,
                url: urlCtrl.text.trim().isEmpty ? null : urlCtrl.text.trim(),
                createdAt: DateTime.now(),
              );

              await fs.createDoc(d);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DocRef>>(
      stream: fs.watchDocsForApp(uid: app.uid, appId: app.id),
      builder: (context, snap) {
        final docs = snap.data ?? const [];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FilledButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text('Add doc reference'),
              onPressed: () => _addDocDialog(context),
            ),
            const SizedBox(height: 12),

            if (docs.isEmpty && snap.connectionState != ConnectionState.waiting)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Center(child: Text('No docs yet.', style: TextStyle(color: Theme.of(context).hintColor))),
              ),

            ...docs.map((d) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ListTile(
                  title: Text(d.label),
                  subtitle: Text(d.type),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if ((d.url ?? '').trim().isNotEmpty)
                        IconButton(
                          tooltip: 'Open link',
                          icon: const Icon(Icons.open_in_new),
                          onPressed: () async {
                            final ok = await launchUrlStringSafe(d.url!);
                            if (!ok && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Could not open link')),
                              );
                            }
                          },
                        ),
                      IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => fs.deleteDoc(d.id),
                      ),
                    ],
                  ),
                ),
              ),
            )),
          ],
        );
      },
    );
  }
}
