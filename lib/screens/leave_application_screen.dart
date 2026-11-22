import 'package:material_ui/material_ui.dart';

import '../app_state.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets/common.dart';

class LeaveApplicationScreen extends StatefulWidget {
  const LeaveApplicationScreen({super.key});

  @override
  State<LeaveApplicationScreen> createState() => _LeaveApplicationScreenState();
}

class _LeaveApplicationScreenState extends State<LeaveApplicationScreen> {
  final _form = GlobalKey<FormState>();
  final _reason = TextEditingController();
  String? _type;
  DateTime? _from;
  DateTime? _to;
  bool _busy = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _pick(bool from) async {
    final initial = (from ? _from : _to) ?? _from ?? DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d == null) return;
    setState(() {
      if (from) {
        _from = d;
        if (_to != null && _to!.isBefore(d)) _to = d;
      } else {
        _to = d;
      }
    });
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (_from == null || _to == null) {
      showSnack(context, 'শুরুর ও শেষের তারিখ দিন');
      return;
    }
    if (_to!.isBefore(_from!)) {
      showSnack(context, 'শেষের তারিখ শুরুর আগে হতে পারে না');
      return;
    }
    setState(() => _busy = true);
    try {
      await AppScope.backendOf(context).submitLeave(
        type: _type!,
        from: _from!,
        to: _to!,
        reason: _reason.text.trim(),
      );
      if (mounted) {
        showSnack(context, 'ছুটির আবেদন জমা হয়েছে');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) showSnack(context, 'জমা দেওয়া যায়নি: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(top: 14, bottom: 6),
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: t,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const TextSpan(
            text: ' *',
            style: TextStyle(color: HpsColors.important),
          ),
        ],
      ),
    ),
  );

  Widget _dateField(DateTime? value, bool from) => InkWell(
    onTap: () => _pick(from),
    child: InputDecorator(
      decoration: const InputDecoration(suffixIcon: Icon(Icons.calendar_month)),
      child: Text(value == null ? '' : fmtDate(value)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leave Application')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Icon(Icons.edit_calendar, size: 72, color: HpsColors.blue),
            const SizedBox(height: 8),
            const Text(
              'Apply for Leave',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            _label('Leave Type'),
            DropdownButtonFormField<String>(
              initialValue: _type,
              hint: const Text('Select Leave Type'),
              items: [
                for (final t in leaveTypes)
                  DropdownMenuItem(value: t, child: Text(t)),
              ],
              onChanged: (v) => setState(() => _type = v),
              validator: (v) => v == null ? 'ছুটির ধরন বেছে নিন' : null,
            ),
            _label('From Date'),
            _dateField(_from, true),
            _label('To Date'),
            _dateField(_to, false),
            _label('Reason'),
            TextFormField(
              controller: _reason,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'Write your reason here...',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'কারণ লিখুন' : null,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: const Text('Submit Application'),
            ),
          ],
        ),
      ),
    );
  }
}
