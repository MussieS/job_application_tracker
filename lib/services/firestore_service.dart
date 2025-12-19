import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/application.dart';
import '../models/task_item.dart';
import '../models/contact.dart';
import '../models/doc_ref.dart';
import '../utils/enums.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  // -------------------------
  // Applications
  // -------------------------

  Stream<List<Application>> watchApplications(String uid) {
    return _db
        .collection('applications')
        .where('uid', isEqualTo: uid)
        .orderBy('lastUpdated', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => Application.fromDoc(d)).toList());
  }

  Stream<List<Application>> watchApplicationsByStatus(String uid, AppStatus status) {
    return _db
        .collection('applications')
        .where('uid', isEqualTo: uid)
        .where('status', isEqualTo: enumToString(status))
        .orderBy('lastUpdated', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => Application.fromDoc(d)).toList());
  }

  Future<String> createApplication(Application app) async {
    final doc = await _db.collection('applications').add(app.toMap());
    return doc.id;
  }

  Future<void> updateApplication(Application app) async {
    await _db.collection('applications').doc(app.id).update(app.toMap());
  }

  Future<void> deleteApplication({
    required String appId,
    bool cascadeDelete = true,
  }) async {
    // For MVP: optionally delete tasks/contacts/docs linked to this app
    if (cascadeDelete) {
      await _cascadeDeleteByAppId(appId);
    }
    await _db.collection('applications').doc(appId).delete();
  }

  Future<void> _cascadeDeleteByAppId(String appId) async {
    // tasks
    final tasksSnap = await _db.collection('tasks').where('appId', isEqualTo: appId).get();
    for (final d in tasksSnap.docs) {
      await d.reference.delete();
    }

    // contacts
    final contactsSnap = await _db.collection('contacts').where('appId', isEqualTo: appId).get();
    for (final d in contactsSnap.docs) {
      await d.reference.delete();
    }

    // docs
    final docsSnap = await _db.collection('docs').where('appId', isEqualTo: appId).get();
    for (final d in docsSnap.docs) {
      await d.reference.delete();
    }
  }

  // -------------------------
  // Tasks
  // -------------------------

  Stream<List<TaskItem>> watchTodayTasks({
    required String uid,
    required DateTime endOfToday,
  }) {
    return _db
        .collection('tasks')
        .where('uid', isEqualTo: uid)
        .where('done', isEqualTo: false)
        .where('dueAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfToday))
        .orderBy('dueAt')
        .snapshots()
        .map((s) => s.docs.map((d) => TaskItem.fromDoc(d)).toList());
  }

  Stream<List<TaskItem>> watchTasksForApp({
    required String uid,
    required String appId,
    bool includeDone = true,
  }) {
    var q = _db
        .collection('tasks')
        .where('uid', isEqualTo: uid)
        .where('appId', isEqualTo: appId)
        .orderBy('dueAt');

    if (!includeDone) {
      q = q.where('done', isEqualTo: false);
    }

    return q.snapshots().map((s) => s.docs.map((d) => TaskItem.fromDoc(d)).toList());
  }

  Future<String> createTask(TaskItem task) async {
    final doc = await _db.collection('tasks').add(task.toMap());
    return doc.id;
  }

  Future<void> updateTask(TaskItem task) async {
    await _db.collection('tasks').doc(task.id).update(task.toMap());
  }

  Future<void> markTaskDone(String taskId, bool done) async {
    await _db.collection('tasks').doc(taskId).update({'done': done});
  }

  Future<void> deleteTask(String taskId) async {
    await _db.collection('tasks').doc(taskId).delete();
  }

  Future<void> createFollowUpTask({
    required String uid,
    required String appId,
    required DateTime dueAt,
    String? companyName,
  }) async {
    final title = companyName == null ? 'Follow up on application' : 'Follow up: $companyName';
    await _db.collection('tasks').add({
      'uid': uid,
      'appId': appId,
      'type': enumToString(TaskType.followup),
      'title': title,
      'dueAt': Timestamp.fromDate(dueAt),
      'done': false,
      'createdAt': Timestamp.now(),
      'notes': null,
    });
  }

  // -------------------------
  // Contacts
  // -------------------------

  Stream<List<Contact>> watchContactsForApp({
    required String uid,
    required String appId,
  }) {
    return _db
        .collection('contacts')
        .where('uid', isEqualTo: uid)
        .where('appId', isEqualTo: appId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => Contact.fromDoc(d)).toList());
  }

  Future<String> createContact(Contact c) async {
    final doc = await _db.collection('contacts').add(c.toMap());
    return doc.id;
  }

  Future<void> deleteContact(String contactId) async {
    await _db.collection('contacts').doc(contactId).delete();
  }

  // -------------------------
  // Docs (resume/cover references)
  // -------------------------

  Stream<List<DocRef>> watchDocsForApp({
    required String uid,
    required String appId,
  }) {
    return _db
        .collection('docs')
        .where('uid', isEqualTo: uid)
        .where('appId', isEqualTo: appId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => DocRef.fromDoc(d)).toList());
  }

  Future<String> createDoc(DocRef d) async {
    final doc = await _db.collection('docs').add(d.toMap());
    return doc.id;
  }

  Future<void> deleteDoc(String docId) async {
    await _db.collection('docs').doc(docId).delete();
  }
}
