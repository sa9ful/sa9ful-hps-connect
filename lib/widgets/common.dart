import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../theme.dart';

final _dateFmt = DateFormat('MMM d, y');
final _timeFmt = DateFormat('hh:mm a');
final _dateTimeFmt = DateFormat('MMM d, y, hh:mm a');
final _meetingFmt = DateFormat('EEE, MMM d, y');

String fmtDate(DateTime d) => _dateFmt.format(d);
String fmtTime(DateTime d) => _timeFmt.format(d);
String fmtDateTime(DateTime d) => _dateTimeFmt.format(d);
String fmtMeetingDay(DateTime d) => _meetingFmt.format(d);

/// চ্যাট তালিকার সময়: আজ হলে সময়, গতকাল হলে "Yesterday", নাহলে তারিখ।
String fmtChatTime(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  if (day == today) return fmtTime(d);
  if (day == today.subtract(const Duration(days: 1))) return 'Yesterday';
  return DateFormat('MMM d').format(d);
}

/// স্কুলের লোগো (assets/images/logo.png)।
class SchoolLogo extends StatelessWidget {
  const SchoolLogo({super.key, this.size = 96});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 12)],
        border: Border.all(color: const Color(0xFFD4A537), width: size / 40),
      ),
      child: ClipOval(
        child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
      ),
    );
  }
}

/// নামের আদ্যক্ষর দিয়ে গোল অ্যাভাটার।
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    super.key,
    required this.name,
    this.radius = 24,
    this.color = HpsColors.blue,
    this.icon,
  });

  final String name;
  final double radius;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final initials = parts.isEmpty
        ? '?'
        : parts.length == 1
        ? parts.first[0]
        : '${parts.first[0]}${parts.last[0]}';
    return CircleAvatar(
      radius: radius,
      backgroundColor: color,
      foregroundColor: Colors.white,
      child: icon != null
          ? Icon(icon, size: radius)
          : Text(
              initials.toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: radius * 0.7,
              ),
            ),
    );
  }
}

/// ডিজাইনের পিল-আকৃতির ট্যাব (All / My Section / Important ...)।
class PillTabs extends StatelessWidget {
  const PillTabs({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: i == selected ? HpsColors.primary : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      color: i == selected ? Colors.white : Colors.black87,
                      fontWeight: i == selected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// ড্যাশবোর্ডের বর্গাকার ফিচার টাইল।
class FeatureTile extends StatelessWidget {
  const FeatureTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge = false,
    this.color = HpsColors.blue,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool badge;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Badge(
                isLabelVisible: badge,
                smallSize: 10,
                backgroundColor: HpsColors.important,
                child: Icon(icon, size: 34, color: color),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ছোট রঙিন লেবেল, যেমন "Important", "Joined"।
class TagChip extends StatelessWidget {
  const TagChip(this.label, {super.key, this.color = HpsColors.important});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// সংখ্যা দেখানো ব্যাজ (চ্যাটের unread, Quick Overview)।
class CountBadge extends StatelessWidget {
  const CountBadge(this.count, {super.key, this.color = HpsColors.important});
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 26),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// খালি তালিকা / লোডিং / এররের সাধারণ অবস্থা।
class AsyncList<T> extends StatelessWidget {
  const AsyncList({
    super.key,
    required this.snapshot,
    required this.builder,
    this.emptyText = 'এখনো কিছু নেই',
  });

  final AsyncSnapshot<List<T>> snapshot;
  final Widget Function(List<T> items) builder;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    if (snapshot.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'ডেটা আনা যায়নি:\n${snapshot.error}',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (!snapshot.hasData) {
      return const Center(child: CircularProgressIndicator());
    }
    final items = snapshot.data!;
    if (items.isEmpty) {
      return Center(
        child: Text(emptyText, style: const TextStyle(color: Colors.black54)),
      );
    }
    return builder(items);
  }
}

/// যে ফিচার এখনো তৈরি হয়নি তার জন্য স্ক্রিন।
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key, required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: HpsColors.blue),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            const Text('শীঘ্রই আসছে (Coming soon)'),
          ],
        ),
      ),
    );
  }
}

void showSnack(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
