import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/enums.dart';

class TaskItem {
  final String id;
  final String uid;
  final String? appId;

  final TaskType type;
  final String title;
  final DateTime dueAt;
  final bool done;

  final DateTime createdAt;
  final String? notes;

  TaskItem({
    required this.id,
    required this.uid,
    required this.type,
    required this.title,
    required this.dueAt,
    required this.done,
    required this.createdAt,
    this.appId,
    this.notes,
  });

  factory TaskItem.fromDoc(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return TaskItem(
      id: doc.id,
      uid: (data['uid'] as String?) ?? '',
      appId: data['appId'] as String?,
      type: enumFromString<TaskType>(
        TaskType.values,
        (data['type'] as String?) ?? 'custom',
        TaskType.custom,
      ),
      title: (data['title'] as String?) ?? '',
      dueAt: ((data['dueAt'] as Timestamp?) ?? Timestamp.now()).toDate(),
      done: (data['done'] as bool?) ?? false,
      createdAt: ((data['createdAt'] as Timestamp?) ?? Timestamp.now()).toDate(),
      notes: data['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'appId': appId,
    'type': enumToString(type),
    'title': title,
    'dueAt': Timestamp.fromDate(dueAt),
    'done': done,
    'createdAt': Timestamp.fromDate(createdAt),
    'notes': notes,
  };

  TaskItem copyWith({
    TaskType? type,
    String? title,
    DateTime? dueAt,
    bool? done,
    String? notes,
    String? appId,
  }) {
    return TaskItem(
      id: id,
      uid: uid,
      appId: appId ?? this.appId,
      type: type ?? this.type,
      title: title ?? this.title,
      dueAt: dueAt ?? this.dueAt,
      done: done ?? this.done,
      createdAt: createdAt,
      notes: notes ?? this.notes,
    );
  }
}
