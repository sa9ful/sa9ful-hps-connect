import 'package:material_ui/material_ui.dart';

import '../app_state.dart';
import '../data/models.dart';
import '../models/user_role.dart';
import '../theme.dart';
import '../widgets/common.dart';

class MeetingsScreen extends StatefulWidget {
  const MeetingsScreen({super.key, required this.role});
  final UserRole role;

  @override
  State<MeetingsScreen> createState() => _MeetingsScreenState();
}

class _MeetingsScreenState extends State<MeetingsScreen> {
  int _tab = 0;
  late final _backend = AppScope.backendOf(context);
  late final Stream<List<Meeting>> _stream = _backend.meetings();

  List<Meeting> _filter(List<Meeting> all) {
    final now = DateTime.now();
    final list = switch (_tab) {
      0 =>
        all.where((m) => !m.startAt.isBefore(now)).toList()
          ..sort((a, b) => a.startAt.compareTo(b.startAt)),
      1 => all.where((m) => m.startAt.isBefore(now)).toList(),
      _ => all.where((m) => m.joined).toList(),
    };
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meetings')),
      body: Column(
        children: [
          PillTabs(
            labels: const ['Upcoming', 'Past', 'My Meetings'],
            selected: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
          Expanded(
            child: StreamBuilder<List<Meeting>>(
              stream: _stream,
              builder: (context, snap) => AsyncList<Meeting>(
                snapshot: snap.hasData
                    ? AsyncSnapshot.withData(
                        ConnectionState.active,
                        _filter(snap.data!),
                      )
                    : snap,
                emptyText: 'কোনো মিটিং নেই',
                builder: (items) => ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _MeetingCard(
                    meeting: items[i],
                    past: _tab == 1,
                    onJoin: () => _backend.joinMeeting(items[i].id),
                  ),
                ),
              ),
            ),
          ),
          if (widget.role.canPublishNotices)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: () => showScheduleMeetingSheet(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Schedule a Meeting'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MeetingCard extends StatelessWidget {
  const _MeetingCard({
    required this.meeting,
    required this.past,
    required this.onJoin,
  });
  final Meeting meeting;
  final bool past;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final small = const TextStyle(fontSize: 12, color: Colors.black54);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.calendar_month, size: 36, color: HpsColors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meeting.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule,
                        size: 14,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '${fmtMeetingDay(meeting.startAt)}  |  ${fmtTime(meeting.startAt)}',
                          style: small,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.place_outlined,
                        size: 14,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 4),
                      Text(meeting.location, style: small),
                    ],
                  ),
                ],
              ),
            ),
            if (meeting.joined)
              const TagChip('Joined', color: HpsColors.success)
            else if (!past)
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(64, 34),
                ),
                onPressed: onJoin,
                child: const Text('Join'),
              ),
          ],
        ),
      ),
    );
  }
}

Future<void> showScheduleMeetingSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => AppScope(
      state: AppScope.of(context),
      child: const _ScheduleMeetingForm(),
    ),
  );
}

class _ScheduleMeetingForm extends StatefulWidget {
  const _ScheduleMeetingForm();

  @override
  State<_ScheduleMeetingForm> createState() => _ScheduleMeetingFormState();
}

class _ScheduleMeetingFormState extends State<_ScheduleMeetingForm> {
  final _title = TextEditingController();
  final _location = TextEditingController(text: 'Conference Room');
  DateTime _at = DateTime.now().add(const Duration(days: 1));
  bool _busy = false;

  Future<void> _pick() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _at,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_at),
    );
    if (t == null) return;
    setState(() => _at = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      await AppScope.backendOf(context).scheduleMeeting(
        title: _title.text.trim(),
        startAt: _at,
        location: _location.text.trim(),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showSnack(context, 'সংরক্ষণ করা যায়নি: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        20,
        16,
        MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Schedule a Meeting',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Title *'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _location,
            decoration: const InputDecoration(labelText: 'Location'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _pick,
            icon: const Icon(Icons.event),
            label: Text(fmtDateTime(_at)),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
