import 'package:material_ui/material_ui.dart';

import '../app_state.dart';
import '../models/user_role.dart';
import '../theme.dart';

IconData roleIcon(UserRole r) => switch (r) {
  UserRole.principal => Icons.workspace_premium,
  UserRole.juniorSectionInCharge => Icons.groups_rounded,
  UserRole.highSectionInCharge => Icons.school_rounded,
  UserRole.residentialInCharge => Icons.bed_rounded,
  UserRole.superAdmin => Icons.settings_rounded,
  UserRole.teacher => Icons.person_rounded,
};

Color roleColor(UserRole r) =>
    r == UserRole.principal ? const Color(0xFFF9A825) : HpsColors.blue;

/// লগইনের পর রোল বেছে নেওয়া। ব্যবহারকারীকে Firestore-এ যে রোলগুলো
/// দেওয়া আছে শুধু সেগুলো চাপা যায়; বাকিগুলো ধূসর থাকে।
class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key, required this.allowed});
  final Set<UserRole> allowed;

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  UserRole? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.allowed.length == 1 ? widget.allowed.first : null;
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'লগআউট',
          onPressed: state.backend.signOut,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            children: [
              const Text(
                'Select Your Role',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.15,
                  children: [
                    for (final r in UserRole.values)
                      _RoleCard(
                        role: r,
                        enabled: widget.allowed.contains(r),
                        selected: _selected == r,
                        onTap: () => setState(() => _selected = r),
                      ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: _selected == null
                    ? null
                    : () => state.selectRole(_selected),
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.enabled,
    required this.selected,
    required this.onTap,
  });

  final UserRole role;
  final bool enabled;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Material(
        color: selected ? HpsColors.sky : Colors.white,
        elevation: 2,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected ? HpsColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(roleIcon(role), size: 40, color: roleColor(role)),
                const SizedBox(height: 8),
                Text(
                  role.labelEn,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
