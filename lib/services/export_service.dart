import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';

import '../models/application.dart';
import '../models/task_item.dart';
import '../utils/enums.dart';

class ExportService {
  Future<File> exportCsv({
    required List<Application> apps,
    required List<TaskItem> tasks,
  }) async {
    final rows = <List<String>>[];

    rows.add([
      'TYPE',
      'ID',
      'Company',
      'Role',
      'Status',
      'Priority',
      'DateApplied',
      'LastUpdated',
      'TaskTitle',
      'TaskType',
      'TaskDueAt',
      'TaskDone',
    ]);

    for (final a in apps) {
      rows.add([
        'APPLICATION',
        a.id,
        a.companyName,
        a.roleTitle,
        enumToString(a.status),
        enumToString(a.priority),
        a.dateApplied.toIso8601String(),
        a.lastUpdated.toIso8601String(),
        '',
        '',
        '',
        '',
      ]);
    }

    for (final t in tasks) {
      rows.add([
        'TASK',
        t.id,
        '',
        '',
        '',
        '',
        '',
        '',
        t.title,
        enumToString(t.type),
        t.dueAt.toIso8601String(),
        t.done.toString(),
      ]);
    }

    final csvText = const ListToCsvConverter().convert(rows);

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/job_tracker_export.csv');
    return file.writeAsString(csvText);
  }
}
