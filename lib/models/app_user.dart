import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_role.dart';

/// Firestore-এর `users/{uid}` ডকুমেন্ট।
class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.section,
    this.active = true,
  });

  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final String? section;
  final bool active;

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return AppUser(
      uid: doc.id,
      name: (data['name'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      role: UserRole.fromId(data['role'] as String?),
      section: data['section'] as String?,
      active: (data['active'] as bool?) ?? true,
    );
  }
}
