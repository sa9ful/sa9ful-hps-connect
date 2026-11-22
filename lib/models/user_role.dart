/// HPS Connect-এর ছয়টি রোল।
///
/// [id] হলো Firestore-এ `users/{uid}.role` ফিল্ডে যে মান রাখা হয়।
/// এই মানগুলো `firestore.rules`-এর সাথে মিলিয়ে রাখতে হবে।
enum UserRole {
  principal('principal', 'প্রিন্সিপাল', 'Principal'),
  juniorSectionInCharge(
    'junior_incharge',
    'জুনিয়র সেকশন ইনচার্জ',
    'Junior Section In-Charge',
  ),
  highSectionInCharge(
    'high_incharge',
    'হাই সেকশন ইনচার্জ',
    'High Section In-Charge',
  ),
  residentialInCharge(
    'residential_incharge',
    'আবাসিক ইনচার্জ',
    'Residential In-Charge',
  ),
  superAdmin('super_admin', 'সুপার অ্যাডমিন', 'Super Admin'),
  teacher('teacher', 'শিক্ষক/স্টাফ', 'Teacher/Staff');

  const UserRole(this.id, this.labelBn, this.labelEn);

  final String id;
  final String labelBn;
  final String labelEn;

  /// নোটিশ ও জরুরি সতর্কবার্তা পাঠাতে পারে এমন রোল।
  bool get canPublishNotices => this != UserRole.teacher;

  /// ব্যবহারকারী ও রোল পরিচালনা করতে পারে।
  bool get canManageUsers => this == UserRole.superAdmin;

  /// প্রিন্সিপালের এক্সিকিউটিভ ড্যাশবোর্ড দেখতে পারে।
  bool get canViewExecutiveDashboard =>
      this == UserRole.principal || this == UserRole.superAdmin;

  static UserRole fromId(String? id) => UserRole.values.firstWhere(
    (r) => r.id == id,
    orElse: () => UserRole.teacher,
  );
}
