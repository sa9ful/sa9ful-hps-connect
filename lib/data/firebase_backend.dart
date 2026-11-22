import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';
import '../models/user_role.dart';
import '../services/push_service.dart';
import 'backend.dart';
import 'models.dart';

/// Firebase Auth + Cloud Firestore দিয়ে আসল বাস্তবায়ন।
/// কালেকশনের গঠন README-র "Firestore ডেটা" অংশে আছে।
class FirebaseBackend implements Backend {
  FirebaseBackend({FirebaseAuth? auth, FirebaseFirestore? db})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = db ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  AppUser? _user;

  @override
  bool get isDemo => false;

  @override
  AppUser? get user => _user;

  String get _uid => _auth.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  @override
  Stream<AppUser?> currentUser() {
    return _auth.authStateChanges().asyncExpand((u) {
      if (u == null) {
        _user = null;
        return Stream.value(null);
      }
      PushService.registerDevice(u.uid);
      return _users.doc(u.uid).snapshots().map((doc) {
        final profile = doc.exists ? AppUser.fromDoc(doc) : null;
        _user = profile;
        if (profile == null || !profile.active) {
          throw NoProfileException(u.email ?? '');
        }
        return profile;
      });
    });
  }

  @override
  Future<void> signInWithEmail(String idOrEmail, String password) =>
      _auth.signInWithEmailAndPassword(
        email: normalizeLoginId(idOrEmail),
        password: password,
      );

  /// Google লগইন। Firebase Console-এ Google প্রোভাইডার চালু করতে হবে এবং
  /// অ্যাপের SHA-1/SHA-256 যোগ করতে হবে (README দেখুন)।
  /// স্টাফ প্রোফাইল (users/{uid}) না থাকলে "অ্যাকাউন্ট চালু হয়নি" দেখাবে।
  @override
  Future<void> signInWithGoogle() =>
      _auth.signInWithProvider(GoogleAuthProvider());

  @override
  Future<void> sendPasswordReset(String idOrEmail) =>
      _auth.sendPasswordResetEmail(email: normalizeLoginId(idOrEmail));

  @override
  Future<void> signOut() => _auth.signOut();

  // ---------------- নোটিশ ----------------

  @override
  Stream<List<Notice>> notices() => _db
      .collection('notices')
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map((s) => s.docs.map(Notice.fromDoc).toList());

  DocumentReference<Map<String, dynamic>> _readDoc(String noticeId) =>
      _db.collection('notices').doc(noticeId).collection('reads').doc(_uid);

  @override
  Stream<ReadStats> readStats(String noticeId) {
    // সংখ্যাগুলো সাময়িক: প্রতি ৩০ সেকেন্ডে aggregate count আবার পড়া হয়।
    Future<ReadStats> load() async {
      final viewed = await _db
          .collection('notices')
          .doc(noticeId)
          .collection('reads')
          .count()
          .get();
      final total = await _users.where('active', isEqualTo: true).count().get();
      return ReadStats(viewed: viewed.count ?? 0, total: total.count ?? 0);
    }

    return Stream<ReadStats>.multi((c) {
      Future<void> tick() async {
        try {
          c.add(await load());
        } catch (e) {
          c.addError(e);
        }
      }

      tick();
      final t = Timer.periodic(const Duration(seconds: 30), (_) => tick());
      c.onCancel = t.cancel;
    });
  }

  @override
  Stream<bool> isAcknowledged(String noticeId) =>
      _readDoc(noticeId)
          .snapshots()
          .map((d) => d.exists && d.data()?['acknowledgedAt'] != null);

  @override
  Future<void> markViewed(String noticeId) => _readDoc(noticeId).set({
    'uid': _uid,
    'name': _user?.displayName ?? '',
    'viewedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  @override
  Future<void> acknowledge(String noticeId) => _readDoc(noticeId).set({
    'uid': _uid,
    'name': _user?.displayName ?? '',
    'viewedAt': FieldValue.serverTimestamp(),
    'acknowledgedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  @override
  Future<void> publishNotice({
    required String title,
    required String body,
    required bool important,
    required String section,
    required UserRole asRole,
  }) => _db.collection('notices').add({
    'title': title,
    'body': body,
    'important': important,
    'section': section,
    'authorId': _uid,
    'authorName': _user?.displayName ?? '',
    'authorRole': asRole.labelEn,
    'createdAt': FieldValue.serverTimestamp(),
  });

  // ---------------- মিটিং ----------------

  @override
  Stream<List<Meeting>> meetings() => _db
      .collection('meetings')
      .orderBy('startAt', descending: true)
      .limit(100)
      .snapshots()
      .map((s) => s.docs.map((d) => Meeting.fromDoc(d, _uid)).toList());

  @override
  Future<void> joinMeeting(String meetingId) =>
      _db.collection('meetings').doc(meetingId).update({
        'joined': FieldValue.arrayUnion([_uid]),
      });

  @override
  Future<void> scheduleMeeting({
    required String title,
    required DateTime startAt,
    required String location,
  }) => _db.collection('meetings').add({
    'title': title,
    'startAt': Timestamp.fromDate(startAt),
    'location': location,
    'createdBy': _uid,
    'joined': <String>[],
    'createdAt': FieldValue.serverTimestamp(),
  });

  // ---------------- টাস্ক ----------------

  @override
  Stream<List<TaskItem>> tasks() {
    final col = _db.collection('tasks');
    final mine = col
        .where('assigneeId', isEqualTo: _uid)
        .snapshots()
        .map((s) => s.docs.map(TaskItem.fromDoc).toList());
    final assigned = col
        .where('assignedById', isEqualTo: _uid)
        .snapshots()
        .map((s) => s.docs.map(TaskItem.fromDoc).toList());
    return combineLatest2(mine, assigned, (a, b) {
      final byId = {
        for (final t in [...a, ...b]) t.id: t,
      };
      return byId.values.toList()..sort((x, y) => x.dueAt.compareTo(y.dueAt));
    });
  }

  @override
  Future<void> setTaskDone(String taskId, bool done) =>
      _db.collection('tasks').doc(taskId).update({'done': done});

  @override
  Future<void> createTask({
    required String title,
    required DateTime dueAt,
    required String assigneeId,
  }) => _db.collection('tasks').add({
    'title': title,
    'dueAt': Timestamp.fromDate(dueAt),
    'assigneeId': assigneeId,
    'assignedById': _uid,
    'done': false,
    'createdAt': FieldValue.serverTimestamp(),
  });

  // ---------------- চ্যাট ----------------

  @override
  Stream<List<ChatThread>> chats() => _db
      .collection('chats')
      .where('members', arrayContains: _uid)
      .snapshots()
      .map(
        (s) =>
            s.docs.map((d) => ChatThread.fromDoc(d, _uid)).toList()
              ..sort((a, b) => b.lastAt.compareTo(a.lastAt)),
      );

  @override
  Stream<List<ChatMessage>> messages(String chatId) {
    // খোলার সময় নিজের unread শূন্য করা হয়।
    _db.collection('chats').doc(chatId).update({'unread.$_uid': 0}).ignore();
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('sentAt', descending: true)
        .limit(200)
        .snapshots()
        .map((s) => s.docs.map(ChatMessage.fromDoc).toList());
  }

  @override
  Future<void> sendMessage(String chatId, String text) async {
    final chat = _db.collection('chats').doc(chatId);
    final batch = _db.batch();
    batch.set(chat.collection('messages').doc(), {
      'text': text,
      'senderId': _uid,
      'senderName': _user?.displayName ?? '',
      'sentAt': FieldValue.serverTimestamp(),
    });
    batch.update(chat, {
      'lastMessage': text,
      'lastAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  // ---------------- অন্যান্য ----------------

  @override
  Stream<List<AppUser>> directory() => _users
      .where('active', isEqualTo: true)
      .snapshots()
      .map(
        (s) =>
            s.docs.map(AppUser.fromDoc).toList()
              ..sort((a, b) => a.displayName.compareTo(b.displayName)),
      );

  @override
  Stream<DashboardStats> stats() {
    final now = Timestamp.now();
    final meetings = _db
        .collection('meetings')
        .where('startAt', isGreaterThanOrEqualTo: now)
        .snapshots()
        .map((s) => s.size);
    final people = directory();
    final base = combineLatest2(people, meetings, (u, m) => (u, m));
    final pending = tasks().map((t) => t.where((x) => !x.done).length);
    // যেসব নোটিশ আমি দেখেছি (collection group query, index: firestore.indexes.json)
    final seen = _db
        .collectionGroup('reads')
        .where('uid', isEqualTo: _uid)
        .snapshots()
        .map((s) => s.docs.map((d) => d.reference.parent.parent!.id).toSet());
    final unread = combineLatest2(
      notices(),
      seen,
      (n, s) => n.where((x) => !s.contains(x.id)).length,
    );
    final work = combineLatest2(pending, unread, (p, u) => (p, u));
    return combineLatest2(base, work, (b, w) {
      final (users, upcoming) = b;
      final (p, unreadCount) = w;
      final staff = users.where((u) => u.department == 'Staff').length;
      return DashboardStats(
        totalUsers: users.length,
        teachers: users.length - staff,
        staff: staff,
        departments: users
            .map((u) => u.department)
            .whereType<String>()
            .toSet()
            .length,
        unreadNotices: unreadCount,
        upcomingMeetings: upcoming,
        pendingTasks: p,
      );
    });
  }

  @override
  Future<void> submitLeave({
    required String type,
    required DateTime from,
    required DateTime to,
    required String reason,
  }) => _db.collection('leaveRequests').add({
    'userId': _uid,
    'userName': _user?.displayName ?? '',
    'type': type,
    'from': Timestamp.fromDate(from),
    'to': Timestamp.fromDate(to),
    'reason': reason,
    'status': 'pending',
    'createdAt': FieldValue.serverTimestamp(),
  });
}

/// লগইন হয়েছে কিন্তু users/{uid} প্রোফাইল নেই বা বন্ধ।
class NoProfileException implements Exception {
  NoProfileException(this.email);
  final String email;
}

/// Firebase-এর এরর কোডকে বাংলা বার্তায় রূপান্তর।
String authErrorMessage(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-email':
        return 'ইমেইল বা ইউজার আইডি সঠিক নয়।';
      case 'user-disabled':
        return 'এই অ্যাকাউন্টটি বন্ধ করা হয়েছে। সুপার অ্যাডমিনের সাথে যোগাযোগ করুন।';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'ইউজার আইডি/ইমেইল বা পাসওয়ার্ড ভুল।';
      case 'too-many-requests':
        return 'অনেকবার চেষ্টা করা হয়েছে। কিছুক্ষণ পর আবার চেষ্টা করুন।';
      case 'network-request-failed':
        return 'ইন্টারনেট সংযোগ পরীক্ষা করুন।';
      case 'web-context-canceled':
      case 'canceled':
        return 'Google লগইন বাতিল করা হয়েছে।';
    }
    return error.message ?? 'লগইন করা যায়নি (${error.code})।';
  }
  return 'কিছু একটা ভুল হয়েছে। আবার চেষ্টা করুন।';
}
