import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/enums.dart';

class Application {
  final String id;
  final String uid;

  final String companyName;
  final String roleTitle;
  final String? location;
  final String? jobUrl;

  final AppStatus status;
  final String? source;
  final Priority priority;

  final DateTime dateApplied;
  final DateTime lastUpdated;

  final List<String> tags;
  final String? notes;

  Application({
    required this.id,
    required this.uid,
    required this.companyName,
    required this.roleTitle,
    required this.status,
    required this.priority,
    required this.dateApplied,
    required this.lastUpdated,
    this.location,
    this.jobUrl,
    this.source,
    this.tags = const [],
    this.notes,
  });

  factory Application.fromDoc(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return Application(
      id: doc.id,
      uid: (data['uid'] as String?) ?? '',
      companyName: (data['companyName'] as String?) ?? '',
      roleTitle: (data['roleTitle'] as String?) ?? '',
      location: data['location'] as String?,
      jobUrl: data['jobUrl'] as String?,
      status: enumFromString<AppStatus>(
        AppStatus.values,
        (data['status'] as String?) ?? 'applied',
        AppStatus.applied,
      ),
      source: data['source'] as String?,
      priority: enumFromString<Priority>(
        Priority.values,
        (data['priority'] as String?) ?? 'medium',
        Priority.medium,
      ),
      dateApplied: ((data['dateApplied'] as Timestamp?) ?? Timestamp.now()).toDate(),
      lastUpdated: ((data['lastUpdated'] as Timestamp?) ?? Timestamp.now()).toDate(),
      tags: List<String>.from((data['tags'] as List?) ?? const []),
      notes: data['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'companyName': companyName,
    'roleTitle': roleTitle,
    'location': location,
    'jobUrl': jobUrl,
    'status': enumToString(status),
    'source': source,
    'priority': enumToString(priority),
    'dateApplied': Timestamp.fromDate(dateApplied),
    'lastUpdated': Timestamp.fromDate(lastUpdated),
    'tags': tags,
    'notes': notes,
  };

  Application copyWith({
    String? companyName,
    String? roleTitle,
    String? location,
    String? jobUrl,
    AppStatus? status,
    String? source,
    Priority? priority,
    DateTime? dateApplied,
    DateTime? lastUpdated,
    List<String>? tags,
    String? notes,
  }) {
    return Application(
      id: id,
      uid: uid,
      companyName: companyName ?? this.companyName,
      roleTitle: roleTitle ?? this.roleTitle,
      location: location ?? this.location,
      jobUrl: jobUrl ?? this.jobUrl,
      status: status ?? this.status,
      source: source ?? this.source,
      priority: priority ?? this.priority,
      dateApplied: dateApplied ?? this.dateApplied,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
    );
  }
}
