import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_item.dart';
import '../utils/enums.dart';

class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.onToggleDone,
    required this.onReschedule,
  });

  final TaskItem task;
  final VoidCallback onToggleDone;
  final VoidCallback onReschedule;

  IconData _iconForType(TaskType t) {
    switch (t) {
      case TaskType.followup:
        return Icons.mark_email_unread_outlined;
      case TaskType.interviewPrep:
        return Icons.school_outlined;
      case TaskType.assessment:
        return Icons.timer_outlined;
      case TaskType.network:
        return Icons.people_outline;
      case TaskType.custom:
        return Icons.task_alt_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('MMM d • h:mm a').format(task.dueAt);

    return Material(
      elevation: 1,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onToggleDone,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(_iconForType(task.type)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(time, style: TextStyle(color: Theme.of(context).hintColor)),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Reschedule',
                onPressed: onReschedule,
                icon: const Icon(Icons.schedule),
              ),
              Checkbox(value: task.done, onChanged: (_) => onToggleDone()),
            ],
          ),
        ),
      ),
    );
  }
}
