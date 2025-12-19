import 'package:cloud_firestore/cloud_firestore.dart';

class DocRef {
  final String id;
  final String uid;
  final String appId;

  final String type; // resume / cover
  final String label; // e.g., "Resume v3 - Quant"
  final String? url;  // optional (Storage later)
  final DateTime createdAt;

  DocRef({
    required this.id,
    required this.uid,
    required this.appId,
    required this.type,
    required this.label,
    required this.createdAt,
    this.url,
  });

  factory DocRef.fromDoc(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return DocRef(
      id: doc.id,
      uid: (data['uid'] as String?) ?? '',
      appId: (data['appId'] as String?) ?? '',
      type: (data['type'] as String?) ?? 'resume',
      label: (data['label'] as String?) ?? '',
      url: data['url'] as String?,
      createdAt: ((data['createdAt'] as Timestamp?) ?? Timestamp.now()).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'appId': appId,
    'type': type,
    'label': label,
    'url': url,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
