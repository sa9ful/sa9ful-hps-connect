import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_role.dart';

/// Firestore-এর `users/{uid}` ডকুমেন্ট।
///
/// `role` হলো প্রধান রোল। কারো একাধিক দায়িত্ব থাকলে (যেমন শিক্ষক ও
/// আবাসিক ইনচার্জ) অতিরিক্ত রোল `roles` অ্যারেতে রাখা যায়; লগইনের পর
/// Role Selection স্ক্রিনে শুধু এই রোলগুলো বেছে নেওয়া যায়।
class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.extraRoles = const [],
    this.section,
    this.department,
    this.photoUrl,
    this.active = true,
  });

  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final List<UserRole> extraRoles;
  final String? section;
  final String? department;
  final String? photoUrl;
  final bool active;

  /// এই ব্যবহারকারী যে রোলগুলোতে ঢুকতে পারে।
  Set<UserRole> get allowedRoles => {role, ...extraRoles};

  String get displayName => name.isEmpty ? email : name;

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return AppUser(
      uid: doc.id,
      name: (data['name'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      role: UserRole.fromId(data['role'] as String?),
      extraRoles: ((data['roles'] as List?) ?? const [])
          .whereType<String>()
          .map(UserRole.fromId)
          .toList(),
      section: data['section'] as String?,
      department: data['department'] as String?,
      photoUrl: data['photoUrl'] as String?,
      active: (data['active'] as bool?) ?? true,
    );
  }
}
