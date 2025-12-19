import 'package:cloud_firestore/cloud_firestore.dart';

class Contact {
  final String id;
  final String uid;
  final String appId;

  final String name;
  final String? role;
  final String? email;
  final String? linkedinUrl;
  final String? notes;

  final DateTime createdAt;

  Contact({
    required this.id,
    required this.uid,
    required this.appId,
    required this.name,
    required this.createdAt,
    this.role,
    this.email,
    this.linkedinUrl,
    this.notes,
  });

  factory Contact.fromDoc(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return Contact(
      id: doc.id,
      uid: (data['uid'] as String?) ?? '',
      appId: (data['appId'] as String?) ?? '',
      name: (data['name'] as String?) ?? '',
      role: data['role'] as String?,
      email: data['email'] as String?,
      linkedinUrl: data['linkedinUrl'] as String?,
      notes: data['notes'] as String?,
      createdAt: ((data['createdAt'] as Timestamp?) ?? Timestamp.now()).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'appId': appId,
    'name': name,
    'role': role,
    'email': email,
    'linkedinUrl': linkedinUrl,
    'notes': notes,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
