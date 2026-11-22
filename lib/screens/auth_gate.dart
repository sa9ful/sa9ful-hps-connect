import 'package:material_ui/material_ui.dart';

import '../app_state.dart';
import '../data/firebase_backend.dart';
import '../models/app_user.dart';
import '../models/user_role.dart';
import 'principal_shell.dart';
import 'login_screen.dart';
import 'role_selection_screen.dart';
import 'splash_screen.dart';
import 'teacher_shell.dart';

/// Splash → Login → Role Selection → রোল অনুযায়ী ড্যাশবোর্ড।
class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    this.splashDuration = const Duration(milliseconds: 1600),
  });
  final Duration splashDuration;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _splashDone = false;
  Stream<AppUser?>? _userStream;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.splashDuration, () {
      if (mounted) setState(() => _splashDone = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    _userStream ??= state.backend.currentUser();
    if (!_splashDone) return const SplashScreen();

    return StreamBuilder<AppUser?>(
      stream: _userStream,
      builder: (context, snap) {
        if (snap.hasError) {
          final e = snap.error;
          return _NoProfile(email: e is NoProfileException ? e.email : '$e');
        }
        if (snap.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        final user = snap.data;
        if (user == null) {
          if (state.activeRole != null) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => state.selectRole(null),
            );
          }
          return const LoginScreen();
        }
        final allowed = user.allowedRoles;
        final role = state.activeRole;
        if (role == null || !allowed.contains(role)) {
          return RoleSelectionScreen(allowed: allowed);
        }
        return switch (role) {
          UserRole.principal ||
          UserRole.superAdmin => PrincipalShell(user: user, role: role),
          _ => TeacherShell(user: user, role: role),
        };
      },
    );
  }
}

class _NoProfile extends StatelessWidget {
  const _NoProfile({required this.email});
  final String email;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_off_outlined, size: 56),
              const SizedBox(height: 16),
              Text(
                'অ্যাকাউন্ট এখনো চালু হয়নি',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                '$email এর জন্য কোনো সক্রিয় প্রোফাইল বা রোল পাওয়া যায়নি। '
                'সুপার অ্যাডমিনকে আপনার রোল সেট করতে বলুন।',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: AppScope.backendOf(context).signOut,
                child: const Text('লগআউট'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
