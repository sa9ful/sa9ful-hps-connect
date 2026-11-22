import 'package:cloud_firestore/cloud_firestore.dart';

DateTime _date(Object? v) {
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  return DateTime.fromMillisecondsSinceEpoch(0);
}

/// নোটিশের সংযুক্ত ফাইল।
class Attachment {
  const Attachment({required this.name, required this.url, this.sizeLabel});
  final String name;
  final String url;
  final String? sizeLabel;

  factory Attachment.fromMap(Map<String, dynamic> m) => Attachment(
    name: (m['name'] as String?) ?? '',
    url: (m['url'] as String?) ?? '',
    sizeLabel: m['size'] as String?,
  );
}

/// notices/{id}
class Notice {
  const Notice({
    required this.id,
    required this.title,
    required this.body,
    required this.authorName,
    required this.authorRoleLabel,
    required this.createdAt,
    this.section = 'all',
    this.important = false,
    this.attachments = const [],
    this.iconKind = 'notice',
  });

  final String id;
  final String title;
  final String body;
  final String authorName;
  final String authorRoleLabel;
  final DateTime createdAt;

  /// 'all' | 'junior' | 'high' | 'residential'
  final String section;
  final bool important;
  final List<Attachment> attachments;

  /// তালিকার আইকন: 'notice' | 'sports' | 'schedule'
  final String iconKind;

  factory Notice.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? const {};
    return Notice(
      id: d.id,
      title: (m['title'] as String?) ?? '',
      body: (m['body'] as String?) ?? '',
      authorName: (m['authorName'] as String?) ?? '',
      authorRoleLabel: (m['authorRole'] as String?) ?? '',
      createdAt: _date(m['createdAt']),
      section: (m['section'] as String?) ?? 'all',
      important: (m['important'] as bool?) ?? false,
      iconKind: (m['iconKind'] as String?) ?? 'notice',
      attachments: ((m['attachments'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(Attachment.fromMap)
          .toList(),
    );
  }
}

/// কতজন নোটিশটি দেখেছে / মোট কতজন।
class ReadStats {
  const ReadStats({required this.viewed, required this.total});
  final int viewed;
  final int total;
}

/// meetings/{id}
class Meeting {
  const Meeting({
    required this.id,
    required this.title,
    required this.startAt,
    required this.location,
    this.joined = false,
  });

  final String id;
  final String title;
  final DateTime startAt;
  final String location;

  /// বর্তমান ব্যবহারকারী যোগ দিয়েছে কি না।
  final bool joined;

  factory Meeting.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> d,
    String uid,
  ) {
    final m = d.data() ?? const {};
    return Meeting(
      id: d.id,
      title: (m['title'] as String?) ?? '',
      startAt: _date(m['startAt']),
      location: (m['location'] as String?) ?? '',
      joined: ((m['joined'] as List?) ?? const []).contains(uid),
    );
  }
}

/// tasks/{id}
class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    required this.dueAt,
    required this.assigneeId,
    required this.assignedById,
    this.done = false,
  });

  final String id;
  final String title;
  final DateTime dueAt;
  final String assigneeId;
  final String assignedById;
  final bool done;

  factory TaskItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? const {};
    return TaskItem(
      id: d.id,
      title: (m['title'] as String?) ?? '',
      dueAt: _date(m['dueAt']),
      assigneeId: (m['assigneeId'] as String?) ?? '',
      assignedById: (m['assignedById'] as String?) ?? '',
      done: (m['done'] as bool?) ?? false,
    );
  }
}

/// chats/{id}
class ChatThread {
  const ChatThread({
    required this.id,
    required this.name,
    required this.isGroup,
    required this.lastMessage,
    required this.lastAt,
    this.unread = 0,
    this.colorIndex = 0,
  });

  final String id;
  final String name;
  final bool isGroup;
  final String lastMessage;
  final DateTime lastAt;
  final int unread;
  final int colorIndex;

  factory ChatThread.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> d,
    String uid,
  ) {
    final m = d.data() ?? const {};
    final unreadMap = (m['unread'] as Map?) ?? const {};
    return ChatThread(
      id: d.id,
      name: (m['name'] as String?) ?? '',
      isGroup: m['type'] == 'group',
      lastMessage: (m['lastMessage'] as String?) ?? '',
      lastAt: _date(m['lastAt']),
      unread: (unreadMap[uid] as num?)?.toInt() ?? 0,
      colorIndex: d.id.hashCode.abs() % 5,
    );
  }
}

/// chats/{id}/messages/{id}
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.senderId,
    required this.senderName,
    required this.sentAt,
  });

  final String id;
  final String text;
  final String senderId;
  final String senderName;
  final DateTime sentAt;

  factory ChatMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? const {};
    return ChatMessage(
      id: d.id,
      text: (m['text'] as String?) ?? '',
      senderId: (m['senderId'] as String?) ?? '',
      senderName: (m['senderName'] as String?) ?? '',
      sentAt: _date(m['sentAt']),
    );
  }
}

/// প্রিন্সিপাল ড্যাশবোর্ডের সংখ্যাগুলো।
class DashboardStats {
  const DashboardStats({
    this.totalUsers = 0,
    this.teachers = 0,
    this.staff = 0,
    this.departments = 0,
    this.unreadNotices = 0,
    this.upcomingMeetings = 0,
    this.pendingTasks = 0,
  });

  final int totalUsers;
  final int teachers;
  final int staff;
  final int departments;
  final int unreadNotices;
  final int upcomingMeetings;
  final int pendingTasks;
}

const leaveTypes = <String>[
  'Casual Leave',
  'Sick Leave',
  'Earned Leave',
  'Maternity Leave',
  'Other',
];
