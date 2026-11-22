import 'package:material_ui/material_ui.dart';

import '../app_state.dart';
import '../data/models.dart';
import '../models/user_role.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// রোল কোন সেকশনের: My Section ট্যাবে এই সেকশনের নোটিশ দেখায়।
String? sectionOf(UserRole r) => switch (r) {
  UserRole.juniorSectionInCharge => 'junior',
  UserRole.highSectionInCharge => 'high',
  UserRole.residentialInCharge => 'residential',
  _ => null,
};

class NoticeBoardScreen extends StatefulWidget {
  const NoticeBoardScreen({super.key, required this.role, this.onBack});
  final UserRole role;
  final VoidCallback? onBack;

  @override
  State<NoticeBoardScreen> createState() => _NoticeBoardScreenState();
}

class _NoticeBoardScreenState extends State<NoticeBoardScreen> {
  int _tab = 0;
  String _query = '';
  bool _searching = false;
  late final Stream<List<Notice>> _stream = AppScope.backendOf(context)
      .notices();

  List<Notice> _filter(List<Notice> all) {
    final section =
        sectionOf(widget.role) ?? AppScope.backendOf(context).user?.section;
    return all.where((n) {
      final inSection = n.section == 'all' || n.section == section;
      if (_tab == 1 && !inSection) return false;
      if (_tab == 2 && !n.important) return false;
      if (_query.isNotEmpty) {
        final q = _query.toLowerCase();
        return n.title.toLowerCase().contains(q) ||
            n.body.toLowerCase().contains(q);
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: widget.onBack ?? () => Navigator.maybePop(context),
        ),
        title: _searching
            ? TextField(
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: const InputDecoration(
                  hintText: 'Search notices',
                  hintStyle: TextStyle(color: Colors.white70),
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _query = v),
              )
            : const Text('Notice Board'),
        actions: [
          IconButton(
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              _searching = !_searching;
              _query = '';
            }),
          ),
        ],
      ),
      floatingActionButton: widget.role.canPublishNotices
          ? FloatingActionButton(
              heroTag: 'notice-fab',
              tooltip: 'Send Notice',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => PublishNoticeScreen(role: widget.role),
                ),
              ),
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          PillTabs(
            labels: const ['All', 'My Section', 'Important'],
            selected: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
          Expanded(
            child: StreamBuilder<List<Notice>>(
              stream: _stream,
              builder: (context, snap) => AsyncList<Notice>(
                snapshot: snap.hasData
                    ? AsyncSnapshot.withData(
                        ConnectionState.active,
                        _filter(snap.data!),
                      )
                    : snap,
                emptyText: 'কোনো নোটিশ নেই',
                builder: (items) => ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _NoticeCard(notice: items[i]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.notice});
  final Notice notice;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (notice.iconKind) {
      'sports' => (Icons.emoji_events, const Color(0xFFF9A825)),
      'schedule' => (Icons.calendar_month, HpsColors.blue),
      _ => (Icons.campaign, HpsColors.important),
    };
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => NoticeDetailsScreen(notice: notice),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 34),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notice.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (notice.important) const TagChip('Important'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notice.body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.black54,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${fmtDate(notice.createdAt)}  •  ${notice.authorName}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NoticeDetailsScreen extends StatefulWidget {
  const NoticeDetailsScreen({super.key, required this.notice});
  final Notice notice;

  @override
  State<NoticeDetailsScreen> createState() => _NoticeDetailsScreenState();
}

class _NoticeDetailsScreenState extends State<NoticeDetailsScreen> {
  bool _busy = false;
  late final _backend = AppScope.backendOf(context);
  late final Stream<bool> _acked = _backend.isAcknowledged(widget.notice.id);
  late final Stream<ReadStats> _stats = _backend.readStats(widget.notice.id);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _backend.markViewed(widget.notice.id).ignore();
  }

  Future<void> _ack() async {
    setState(() => _busy = true);
    try {
      await _backend.acknowledge(widget.notice.id);
    } catch (e) {
      if (mounted) showSnack(context, 'সংরক্ষণ করা যায়নি: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.notice;
    return Scaffold(
      appBar: AppBar(title: const Text('Notice Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (n.important)
            const Align(
              alignment: Alignment.centerLeft,
              child: TagChip('Important'),
            ),
          const SizedBox(height: 8),
          Text(
            n.title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              InitialsAvatar(name: n.authorName, radius: 16),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n.authorRoleLabel.isEmpty
                        ? n.authorName
                        : n.authorRoleLabel,
                  ),
                  Text(
                    fmtDateTime(n.createdAt),
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(n.body, style: const TextStyle(fontSize: 16, height: 1.45)),
          for (final a in n.attachments) ...[
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.picture_as_pdf,
                  color: HpsColors.important,
                  size: 34,
                ),
                title: Text(
                  a.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: a.sizeLabel == null ? null : Text(a.sizeLabel!),
                trailing: const Icon(Icons.download, color: HpsColors.blue),
                // অনুমান: ডাউনলোড Firebase Storage যুক্ত হলে চালু হবে।
                onTap: () => showSnack(context, 'ডাউনলোড শীঘ্রই আসছে'),
              ),
            ),
          ],
          const SizedBox(height: 20),
          const Text(
            'Acknowledge this notice',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          StreamBuilder<bool>(
            stream: _acked,
            builder: (context, snap) {
              final done = snap.data ?? false;
              return FilledButton.icon(
                style: done
                    ? FilledButton.styleFrom(backgroundColor: HpsColors.success)
                    : null,
                onPressed: done || _busy ? null : _ack,
                icon: const Icon(Icons.check),
                label: Text(
                  done ? 'Acknowledged' : 'I have read and understood',
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          StreamBuilder<ReadStats>(
            stream: _stats,
            builder: (context, snap) {
              final s = snap.data;
              return Card(
                child: ListTile(
                  title: Text(
                    s == null
                        ? 'Viewed: …'
                        : 'Viewed: ${s.viewed} / ${s.total}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: TextButton(
                    onPressed: () =>
                        showSnack(context, 'View List শীঘ্রই আসছে'),
                    child: const Text('View List'),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class PublishNoticeScreen extends StatefulWidget {
  const PublishNoticeScreen({super.key, required this.role});
  final UserRole role;

  @override
  State<PublishNoticeScreen> createState() => _PublishNoticeScreenState();
}

class _PublishNoticeScreenState extends State<PublishNoticeScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  bool _important = false;
  late String _section = sectionOf(widget.role) ?? 'all';
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await AppScope.backendOf(context).publishNotice(
        title: _title.text.trim(),
        body: _body.text.trim(),
        important: _important,
        section: _section,
        asRole: widget.role,
      );
      if (mounted) {
        showSnack(context, 'নোটিশ পাঠানো হয়েছে');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) showSnack(context, 'পাঠানো যায়নি: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send Notice')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title *'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'শিরোনাম লিখুন' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _body,
              minLines: 5,
              maxLines: 10,
              decoration: const InputDecoration(
                labelText: 'Details *',
                alignLabelWithHint: true,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'বিস্তারিত লিখুন' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _section,
              decoration: const InputDecoration(labelText: 'Audience'),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All staff')),
                DropdownMenuItem(
                  value: 'junior',
                  child: Text('Junior Section'),
                ),
                DropdownMenuItem(value: 'high', child: Text('High Section')),
                DropdownMenuItem(
                  value: 'residential',
                  child: Text('Residential'),
                ),
              ],
              onChanged: (v) => setState(() => _section = v ?? 'all'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Mark as Important'),
              value: _important,
              onChanged: (v) => setState(() => _important = v),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _busy ? null : _submit,
              icon: const Icon(Icons.send),
              label: const Text('Publish Notice'),
            ),
          ],
        ),
      ),
    );
  }
}
