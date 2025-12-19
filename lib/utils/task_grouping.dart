import '../models/task_item.dart';
import 'date_utils.dart';

class GroupedTasks {
  final List<TaskItem> overdue;
  final List<TaskItem> dueToday;
  final List<TaskItem> later;

  GroupedTasks({
    required this.overdue,
    required this.dueToday,
    required this.later,
  });
}

GroupedTasks groupTasks(List<TaskItem> tasks, DateTime now) {
  final overdue = <TaskItem>[];
  final dueToday = <TaskItem>[];
  final later = <TaskItem>[];

  for (final t in tasks) {
    if (DateUtilsX.isOverdue(t.dueAt, now) && !DateUtilsX.isSameDay(t.dueAt, now)) {
      overdue.add(t);
    } else if (DateUtilsX.isDueToday(t.dueAt, now)) {
      dueToday.add(t);
    } else {
      later.add(t);
    }
  }

  overdue.sort((a, b) => a.dueAt.compareTo(b.dueAt));
  dueToday.sort((a, b) => a.dueAt.compareTo(b.dueAt));
  later.sort((a, b) => a.dueAt.compareTo(b.dueAt));

  return GroupedTasks(overdue: overdue, dueToday: dueToday, later: later);
}
