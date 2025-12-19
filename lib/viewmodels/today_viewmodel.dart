import 'package:flutter/foundation.dart';
import '../models/task_item.dart';
import '../services/firestore_service.dart';

class TodayViewModel extends ChangeNotifier {
  TodayViewModel(this._firestore);

  final FirestoreService _firestore;

  Stream<List<TaskItem>> watchToday({required String uid, required DateTime endOfToday}) {
    return _firestore.watchTodayTasks(uid: uid, endOfToday: endOfToday);
  }

  Future<void> toggleDone(TaskItem t) async {
    await _firestore.markTaskDone(t.id, !t.done);
  }

  Future<void> reschedule(TaskItem t, DateTime newDueAt) async {
    final updated = t.copyWith(dueAt: newDueAt);
    await _firestore.updateTask(updated);
  }

  Future<void> addTask(TaskItem t) async {
    await _firestore.createTask(t);
  }
}
