import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/task_item.dart';
import '../../services/firestore_service.dart';
import '../../utils/date_utils.dart';
import '../../utils/enums.dart';
import '../../utils/task_grouping.dart';
import '../../viewmodels/today_viewmodel.dart';
import '../../widgets/section_header.dart';
import '../../widgets/task_tile.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key, required this.uid});

  final String uid;

  DateTime _endOfToday() => DateUtilsX.endOfDay(DateTime.now());

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TodayViewModel(FirestoreService()),
      child: _TodayBody(uid: uid, endOfToday: _endOfToday()),
    );
  }
}

class _TodayBody extends StatelessWidget {
  const _TodayBody({required this.uid, required this.endOfToday});

  final String uid;
  final DateTime endOfToday;

  Future<void> _showAddTaskDialog(BuildContext context, TodayViewModel vm) async {
    final titleCtrl = TextEditingController();
    TaskType type = TaskType.custom;
    DateTime dueAt = DateTime.now().add(const Duration(hours: 1));

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add task'),
          content: StatefulBuilder(
            builder: (ctx, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<TaskType>(
                    value: type,
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(),
                    ),
                    items: TaskType.values
                        .map((t) => DropdownMenuItem(
                      value: t,
                      child: Text(enumToString(t)),
                    ))
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
                            setState(() {
                              dueAt = DateTime(picked.year, picked.month, picked.day, dueAt.hour, dueAt.minute);
                            });
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
                            setState(() {
                              dueAt = DateTime(dueAt.year, dueAt.month, dueAt.day, picked.hour, picked.minute);
                            });
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
                  uid: uid,
                  appId: null,
                  type: type,
                  title: title,
                  dueAt: dueAt,
                  done: false,
                  createdAt: DateTime.now(),
                  notes: null,
                );

                await vm.addTask(task);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showRescheduleSheet(BuildContext context, TodayViewModel vm, TaskItem t) async {
    final now = DateTime.now();

    Future<void> pickCustom() async {
      final date = await showDatePicker(
        context: context,
        firstDate: now.subtract(const Duration(days: 365)),
        lastDate: now.add(const Duration(days: 365)),
        initialDate: t.dueAt,
      );
      if (date == null) return;

      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(t.dueAt),
      );
      if (time == null) return;

      final newDue = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      await vm.reschedule(t, newDue);
    }

    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(t.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),

                FilledButton.icon(
                  icon: const Icon(Icons.today),
                  label: const Text('Move to Today (6:00 PM)'),
                  onPressed: () async {
                    final d = DateUtilsX.startOfDay(now);
                    final newDue = DateTime(d.year, d.month, d.day, 18, 0);
                    await vm.reschedule(t, newDue);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 8),

                FilledButton.tonalIcon(
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Move to Tomorrow (10:00 AM)'),
                  onPressed: () async {
                    final tomorrow = DateUtilsX.addDays(DateUtilsX.startOfDay(now), 1);
                    final newDue = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 10, 0);
                    await vm.reschedule(t, newDue);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 8),

                OutlinedButton.icon(
                  icon: const Icon(Icons.edit_calendar),
                  label: const Text('Pick date & time'),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await pickCustom();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TodayViewModel>();
    final now = DateTime.now();

    return StreamBuilder<List<TaskItem>>(
      stream: vm.watchToday(uid: uid, endOfToday: endOfToday),
      builder: (context, snap) {
        final title = DateFormat('EEEE, MMM d').format(now);

        if (snap.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: Text(title)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return Scaffold(
            appBar: AppBar(title: Text(title)),
            body: Center(child: Text('Error: ${snap.error}')),
          );
        }

        final tasks = snap.data ?? [];
        final grouped = groupTasks(tasks, now);

        return Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (tasks.isEmpty) ...[
                const SizedBox(height: 40),
                const Icon(Icons.check_circle_outline, size: 56),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    "You're clear for today.",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    "Add a task to stay consistent with follow-ups and interviews.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).hintColor),
                  ),
                ),
              ],

              if (grouped.overdue.isNotEmpty) ...[
                const SectionHeader(title: 'Overdue'),
                ...grouped.overdue.map(
                      (t) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TaskTile(
                      task: t,
                      onToggleDone: () => vm.toggleDone(t),
                      onReschedule: () => _showRescheduleSheet(context, vm, t),
                    ),
                  ),
                ),
              ],

              if (grouped.dueToday.isNotEmpty) ...[
                const SectionHeader(title: 'Due Today'),
                ...grouped.dueToday.map(
                      (t) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TaskTile(
                      task: t,
                      onToggleDone: () => vm.toggleDone(t),
                      onReschedule: () => _showRescheduleSheet(context, vm, t),
                    ),
                  ),
                ),
              ],

              // NOTE: "Later" won't show in the Today stream because we query <= endOfToday.
              // We keep the section for future expansion when we add a "Upcoming" query.
            ],
          ),
        );
      },
    );
  }
}
