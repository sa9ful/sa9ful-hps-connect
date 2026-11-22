import 'dart:async';

import '../models/app_user.dart';
import '../models/user_role.dart';
import 'backend.dart';
import 'models.dart';

/// একটি মান রাখে এবং প্রতিটি নতুন listener-কে সাথে সাথে বর্তমান মান দেয়।
class _Value<T> {
  _Value(this._value);
  T _value;
  final _changes = StreamController<T>.broadcast();

  T get value => _value;
  set value(T v) {
    _value = v;
    _changes.add(v);
  }

  Stream<T> get stream async* {
    yield _value;
    yield* _changes.stream;
  }
}

/// Firebase কনফিগ ছাড়া বানানো APK-তে ডিজাইনের নমুনা ডেটা দিয়ে
/// পুরো অ্যাপ ঘুরে দেখার জন্য। কোনো ডেটা সার্ভারে যায় না।
class DemoBackend implements Backend {
  DemoBackend() {
    final now = DateTime.now();
    final d = DateTime(now.year, now.month, now.day);
    _notices.value = [
      Notice(
        id: 'n1',
        title: 'Staff Meeting – This Saturday',
        body:
            'A general staff meeting will be held on Saturday at 10:00 AM in the '
            'Conference Room.\n\nAll teachers and staff are requested to be '
            'present on time.',
        authorName: 'Principal',
        authorRoleLabel: 'Principal',
        createdAt: d.add(const Duration(hours: 9, minutes: 30)),
        important: true,
        attachments: const [
          Attachment(name: 'Meeting_Agenda.pdf', url: '', sizeLabel: '1.2 MB'),
        ],
      ),
      Notice(
        id: 'n2',
        title: 'Annual Sports – Preparation',
        body: 'Please submit the participant list by Nov 25, 2026.',
        authorName: 'High Section',
        authorRoleLabel: 'High Section In-Charge',
        createdAt: d.subtract(const Duration(days: 1, hours: -11)),
        section: 'high',
        iconKind: 'sports',
      ),
      Notice(
        id: 'n3',
        title: 'Ramadan Schedule',
        body: 'Class and office timing during Ramadan.',
        authorName: 'Admin',
        authorRoleLabel: 'Super Admin',
        createdAt: d.subtract(const Duration(days: 3, hours: -10)),
        iconKind: 'schedule',
      ),
    ];
    _meetings.value = [
      Meeting(
        id: 'm1',
        title: 'General Staff Meeting',
        startAt: _nextWeekday(d, DateTime.saturday, 10),
        location: 'Conference Room',
        joined: true,
      ),
      Meeting(
        id: 'm2',
        title: 'Sports Committee Meeting',
        startAt: _nextWeekday(d, DateTime.monday, 15),
        location: 'Meeting Room',
      ),
      Meeting(
        id: 'm3',
        title: 'Academic Review Meeting',
        startAt: _nextWeekday(d, DateTime.thursday, 16),
        location: 'Conference Room',
      ),
      Meeting(
        id: 'm4',
        title: 'Parents Day Planning',
        startAt: d.subtract(const Duration(days: 6, hours: -11)),
        location: 'Principal Office',
        joined: true,
      ),
    ];
    _tasks.value = [
      TaskItem(
        id: 't1',
        title: 'Prepare sports participant list',
        dueAt: d.add(const Duration(days: 1)),
        assigneeId: _me,
        assignedById: 'principal',
      ),
      TaskItem(
        id: 't2',
        title: 'Submit question papers (Class VIII)',
        dueAt: d.add(const Duration(days: 2)),
        assigneeId: _me,
        assignedById: 'high',
      ),
      TaskItem(
        id: 't3',
        title: 'Event duty (Sirat & Ghazal)',
        dueAt: d.add(const Duration(days: 6)),
        assigneeId: _me,
        assignedById: 'principal',
      ),
      TaskItem(
        id: 't4',
        title: 'Update class routine',
        dueAt: d.subtract(const Duration(days: 1)),
        assigneeId: _me,
        assignedById: 'junior',
        done: true,
      ),
      TaskItem(
        id: 't5',
        title: 'Check hostel attendance register',
        dueAt: d.add(const Duration(days: 3)),
        assigneeId: 'residential',
        assignedById: _me,
      ),
    ];
    _chats.value = [
      ChatThread(
        id: 'c1',
        name: 'Principal',
        isGroup: false,
        lastMessage: 'Please check the latest notice and confirm.',
        lastAt: d.add(const Duration(hours: 10, minutes: 5)),
        unread: 1,
        colorIndex: 0,
      ),
      ChatThread(
        id: 'c2',
        name: 'High Section Team',
        isGroup: true,
        lastMessage: 'Sports preparation meeting at 2 PM.',
        lastAt: d.add(const Duration(hours: 9, minutes: 40)),
        unread: 3,
        colorIndex: 1,
      ),
      ChatThread(
        id: 'c3',
        name: 'Junior Section',
        isGroup: true,
        lastMessage: 'Class routine updated.',
        lastAt: d.subtract(const Duration(hours: 6)),
        colorIndex: 2,
      ),
      ChatThread(
        id: 'c4',
        name: 'Residential Team',
        isGroup: true,
        lastMessage: 'New duty roster uploaded.',
        lastAt: d.subtract(const Duration(hours: 8)),
        colorIndex: 3,
      ),
      ChatThread(
        id: 'c5',
        name: 'Admin Office',
        isGroup: false,
        lastMessage: 'Please submit leave form today.',
        lastAt: d.subtract(const Duration(days: 3)),
        colorIndex: 4,
      ),
    ];
    for (final c in _chats.value) {
      _messages[c.id] = _Value([
        ChatMessage(
          id: '${c.id}-1',
          text: c.lastMessage,
          senderId: c.id,
          senderName: c.name,
          sentAt: c.lastAt,
        ),
      ]);
    }
  }

  static const _me = 'demo-user';
  static const _demoTotal = 150;

  static DateTime _nextWeekday(DateTime from, int weekday, int hour) {
    var days = (weekday - from.weekday) % 7;
    if (days == 0) days = 7;
    return from.add(Duration(days: days, hours: hour));
  }

  final _user = _Value<AppUser?>(null);
  final _notices = _Value<List<Notice>>(const []);
  final _meetings = _Value<List<Meeting>>(const []);
  final _tasks = _Value<List<TaskItem>>(const []);
  final _chats = _Value<List<ChatThread>>(const []);
  final _messages = <String, _Value<List<ChatMessage>>>{};
  final _viewed = _Value<Set<String>>({});
  final _acked = _Value<Set<String>>({});

  @override
  bool get isDemo => true;

  @override
  AppUser? get user => _user.value;

  @override
  Stream<AppUser?> currentUser() => _user.stream;

  @override
  Future<void> signInWithEmail(String idOrEmail, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    _user.value = AppUser(
      uid: _me,
      name: 'Md. Saiful Islam',
      email: normalizeLoginId(idOrEmail.isEmpty ? 'demo' : idOrEmail),
      role: UserRole.teacher,
      // ডেমোতে সব রোল দেখা যায়।
      extraRoles: UserRole.values,
      department: 'Science',
    );
  }

  @override
  Future<void> signInWithGoogle() => signInWithEmail('demo', '');

  @override
  Future<void> sendPasswordReset(String idOrEmail) async {}

  @override
  Future<void> signOut() async => _user.value = null;

  @override
  Stream<List<Notice>> notices() => _notices.stream;

  @override
  Stream<ReadStats> readStats(String noticeId) => _viewed.stream.map(
    (v) => ReadStats(
      viewed: 111 + (v.contains(noticeId) ? 1 : 0),
      total: _demoTotal,
    ),
  );

  @override
  Stream<bool> isAcknowledged(String noticeId) =>
      _acked.stream.map((a) => a.contains(noticeId));

  @override
  Future<void> markViewed(String noticeId) async =>
      _viewed.value = {..._viewed.value, noticeId};

  @override
  Future<void> acknowledge(String noticeId) async {
    await markViewed(noticeId);
    _acked.value = {..._acked.value, noticeId};
  }

  @override
  Future<void> publishNotice({
    required String title,
    required String body,
    required bool important,
    required String section,
    required UserRole asRole,
  }) async {
    _notices.value = [
      Notice(
        id: 'n${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        body: body,
        authorName: user?.displayName ?? '',
        authorRoleLabel: asRole.labelEn,
        createdAt: DateTime.now(),
        important: important,
        section: section,
      ),
      ..._notices.value,
    ];
  }

  @override
  Stream<List<Meeting>> meetings() => _meetings.stream;

  @override
  Future<void> joinMeeting(String meetingId) async {
    _meetings.value = [
      for (final m in _meetings.value)
        m.id == meetingId
            ? Meeting(
                id: m.id,
                title: m.title,
                startAt: m.startAt,
                location: m.location,
                joined: true,
              )
            : m,
    ];
  }

  @override
  Future<void> scheduleMeeting({
    required String title,
    required DateTime startAt,
    required String location,
  }) async {
    _meetings.value = [
      Meeting(
        id: 'm${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        startAt: startAt,
        location: location,
        joined: true,
      ),
      ..._meetings.value,
    ];
  }

  @override
  Stream<List<TaskItem>> tasks() => _tasks.stream;

  @override
  Future<void> setTaskDone(String taskId, bool done) async {
    _tasks.value = [
      for (final t in _tasks.value)
        t.id == taskId
            ? TaskItem(
                id: t.id,
                title: t.title,
                dueAt: t.dueAt,
                assigneeId: t.assigneeId,
                assignedById: t.assignedById,
                done: done,
              )
            : t,
    ];
  }

  @override
  Future<void> createTask({
    required String title,
    required DateTime dueAt,
    required String assigneeId,
  }) async {
    _tasks.value = [
      ..._tasks.value,
      TaskItem(
        id: 't${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        dueAt: dueAt,
        assigneeId: assigneeId,
        assignedById: _me,
      ),
    ];
  }

  @override
  Stream<List<ChatThread>> chats() => _chats.stream;

  @override
  Stream<List<ChatMessage>> messages(String chatId) =>
      (_messages[chatId] ??= _Value(
        const [],
      )).stream.map((l) => l.reversed.toList());

  @override
  Future<void> sendMessage(String chatId, String text) async {
    final box = _messages[chatId] ??= _Value(const []);
    box.value = [
      ...box.value,
      ChatMessage(
        id: '$chatId-${box.value.length + 1}',
        text: text,
        senderId: _me,
        senderName: user?.displayName ?? '',
        sentAt: DateTime.now(),
      ),
    ];
  }

  @override
  Stream<List<AppUser>> directory() => Stream.value(const [
    AppUser(
      uid: 'principal',
      name: 'Principal',
      email: 'principal@hps.edu.bd',
      role: UserRole.principal,
    ),
    AppUser(
      uid: 'junior',
      name: 'Junior Section In-Charge',
      email: 'junior@hps.edu.bd',
      role: UserRole.juniorSectionInCharge,
    ),
    AppUser(
      uid: 'high',
      name: 'High Section In-Charge',
      email: 'high@hps.edu.bd',
      role: UserRole.highSectionInCharge,
    ),
    AppUser(
      uid: 'residential',
      name: 'Residential In-Charge',
      email: 'residential@hps.edu.bd',
      role: UserRole.residentialInCharge,
    ),
    AppUser(
      uid: _me,
      name: 'Md. Saiful Islam',
      email: 'saiful@hps.edu.bd',
      role: UserRole.teacher,
      department: 'Science',
    ),
  ]);

  @override
  Stream<DashboardStats> stats() => Stream.value(
    const DashboardStats(
      totalUsers: 150,
      teachers: 126,
      staff: 24,
      departments: 6,
      unreadNotices: 12,
      upcomingMeetings: 3,
      pendingTasks: 5,
    ),
  );

  @override
  Future<void> submitLeave({
    required String type,
    required DateTime from,
    required DateTime to,
    required String reason,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }
}
