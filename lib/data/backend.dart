import '../models/app_user.dart';
import '../models/user_role.dart';
import 'models.dart';

/// "User ID" দিয়ে লগইন করলে (ইমেইলে '@' না থাকলে) এই ডোমেইন যোগ হয়,
/// যেমন `saiful` → `saiful@hps.edu.bd`।
/// অনুমান: স্কুলের আসল ইমেইল ডোমেইন জানা নেই, প্রয়োজনে এখানে বদলান।
const String kUserIdEmailDomain = 'hps.edu.bd';

String normalizeLoginId(String input) {
  final v = input.trim().toLowerCase();
  return v.contains('@') ? v : '$v@$kUserIdEmailDomain';
}

/// অ্যাপের সব ডেটা ও লগইন এই ইন্টারফেস দিয়ে যায়।
/// দুটি বাস্তবায়ন: [FirebaseBackend] (আসল) ও [DemoBackend]
/// (Firebase কনফিগ না থাকলে নমুনা ডেটা দিয়ে পুরো UI দেখায়)।
abstract class Backend {
  bool get isDemo;

  /// null মানে লগআউট অবস্থা।
  Stream<AppUser?> currentUser();
  AppUser? get user;

  Future<void> signInWithEmail(String idOrEmail, String password);
  Future<void> signInWithGoogle();
  Future<void> sendPasswordReset(String idOrEmail);
  Future<void> signOut();

  // ---- নোটিশ ----
  Stream<List<Notice>> notices();
  Stream<ReadStats> readStats(String noticeId);
  Stream<bool> isAcknowledged(String noticeId);
  Future<void> markViewed(String noticeId);
  Future<void> acknowledge(String noticeId);
  Future<void> publishNotice({
    required String title,
    required String body,
    required bool important,
    required String section,
    required UserRole asRole,
  });

  // ---- মিটিং ----
  Stream<List<Meeting>> meetings();
  Future<void> joinMeeting(String meetingId);
  Future<void> scheduleMeeting({
    required String title,
    required DateTime startAt,
    required String location,
  });

  // ---- টাস্ক ----
  Stream<List<TaskItem>> tasks();
  Future<void> setTaskDone(String taskId, bool done);
  Future<void> createTask({
    required String title,
    required DateTime dueAt,
    required String assigneeId,
  });

  // ---- চ্যাট ----
  Stream<List<ChatThread>> chats();
  Stream<List<ChatMessage>> messages(String chatId);
  Future<void> sendMessage(String chatId, String text);

  // ---- অন্যান্য ----
  Stream<List<AppUser>> directory();
  Stream<DashboardStats> stats();
  Future<void> submitLeave({
    required String type,
    required DateTime from,
    required DateTime to,
    required String reason,
  });
}

/// দুটি স্ট্রিমের সর্বশেষ মান মিলিয়ে নতুন স্ট্রিম (বাড়তি প্যাকেজ ছাড়া)।
Stream<R> combineLatest2<A, B, R>(
  Stream<A> a,
  Stream<B> b,
  R Function(A, B) combine,
) {
  return Stream<R>.multi((c) {
    late A lastA;
    late B lastB;
    var hasA = false, hasB = false, open = 2;
    void emit() {
      if (hasA && hasB) c.add(combine(lastA, lastB));
    }

    void done() {
      if (--open == 0) c.close();
    }

    final sa = a.listen(
      (v) {
        lastA = v;
        hasA = true;
        emit();
      },
      onError: c.addError,
      onDone: done,
    );
    final sb = b.listen(
      (v) {
        lastB = v;
        hasB = true;
        emit();
      },
      onError: c.addError,
      onDone: done,
    );
    c.onCancel = () async {
      await sa.cancel();
      await sb.cancel();
    };
  });
}
