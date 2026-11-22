import 'package:material_ui/material_ui.dart';

import '../app_state.dart';
import '../data/models.dart';
import '../models/app_user.dart';
import '../models/user_role.dart';
import '../theme.dart';
import '../widgets/common.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key, required this.role, this.onBack});
  final UserRole role;
  final VoidCallback? onBack;

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  int _tab = 0;
  late final _backend = AppScope.backendOf(context);
  late final Stream<List<TaskItem>> _stream = _backend.tasks();

  List<TaskItem> _filter(List<TaskItem> all) {
    final me = _backend.user?.uid;
    return switch (_tab) {
      // My Tasks: আমাকে দেওয়া সব কাজ (শেষ হওয়াগুলো নিচে কাটা দাগে)
      0 =>
        all.where((t) => t.assigneeId == me).toList()..sort(
          (a, b) =>
              a.done == b.done ? a.dueAt.compareTo(b.dueAt) : (a.done ? 1 : -1),
        ),
      // Assigned: আমি অন্যকে দিয়েছি
      1 =>
        all.where((t) => t.assignedById == me && t.assigneeId != me).toList(),
      _ => all.where((t) => t.done).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: widget.onBack ?? () => Navigator.maybePop(context),
        ),
        title: const Text('Tasks'),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'task-fab',
        tooltip: 'Assign Task',
        onPressed: () => showAssignTaskSheet(context),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          PillTabs(
            labels: const ['My Tasks', 'Assigned', 'Completed'],
            selected: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
          Expanded(
            child: StreamBuilder<List<TaskItem>>(
              stream: _stream,
              builder: (context, snap) => AsyncList<TaskItem>(
                snapshot: snap.hasData
                    ? AsyncSnapshot.withData(
                        ConnectionState.active,
                        _filter(snap.data!),
                      )
                    : snap,
                emptyText: 'কোনো টাস্ক নেই',
                builder: (items) => ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final t = items[i];
                    final canToggle = t.assigneeId == _backend.user?.uid;
                    return CheckboxListTile(
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      value: t.done,
                      onChanged: canToggle
                          ? (v) => _backend.setTaskDone(t.id, v ?? false)
                          : null,
                      title: Text(
                        t.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          decoration: t.done
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      subtitle: Text(
                        'Due: ${fmtDate(t.dueAt)}',
                        style: const TextStyle(color: HpsColors.important),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showAssignTaskSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) =>
        AppScope(state: AppScope.of(context), child: const _AssignTaskForm()),
  );
}

class _AssignTaskForm extends StatefulWidget {
  const _AssignTaskForm();

  @override
  State<_AssignTaskForm> createState() => _AssignTaskFormState();
}

class _AssignTaskFormState extends State<_AssignTaskForm> {
  final _title = TextEditingController();
  DateTime _due = DateTime.now().add(const Duration(days: 3));
  String? _assignee;
  bool _busy = false;
  late final _backend = AppScope.backendOf(context);
  late final Stream<List<AppUser>> _people = _backend.directory();

  Future<void> _save() async {
    final assignee = _assignee ?? _backend.user?.uid;
    if (_title.text.trim().isEmpty || assignee == null) return;
    setState(() => _busy = true);
    try {
      await _backend.createTask(
        title: _title.text.trim(),
        dueAt: _due,
        assigneeId: assignee,
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
            'Assign Task',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Task *'),
          ),
          const SizedBox(height: 10),
          StreamBuilder<List<AppUser>>(
            stream: _people,
            builder: (context, snap) => DropdownButtonFormField<String>(
              initialValue: _assignee,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Assign to (খালি রাখলে নিজেকে)',
              ),
              items: [
                for (final u in snap.data ?? const <AppUser>[])
                  DropdownMenuItem(
                    value: u.uid,
                    child: Text('${u.displayName} (${u.role.labelEn})'),
                  ),
              ],
              onChanged: (v) => setState(() => _assignee = v),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _due,
                firstDate: DateTime.now().subtract(const Duration(days: 1)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (d != null) setState(() => _due = d);
            },
            icon: const Icon(Icons.event),
            label: Text('Due: ${fmtDate(_due)}'),
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
