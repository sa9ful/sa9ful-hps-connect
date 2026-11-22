import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/push_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';

/// লগইন অবস্থা ও Firestore প্রোফাইল দেখে সঠিক স্ক্রিনে পাঠায়।
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    return StreamBuilder<User?>(
      stream: auth.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _Loading();
        }
        final user = snap.data;
        if (user == null) return LoginScreen(auth: auth);

        PushService.registerDevice(user.uid);
        return StreamBuilder<AppUser?>(
          stream: auth.profile(user.uid),
          builder: (context, profileSnap) {
            if (profileSnap.connectionState == ConnectionState.waiting) {
              return const _Loading();
            }
            final profile = profileSnap.data;
            if (profileSnap.hasError || profile == null || !profile.active) {
              return _NoProfile(auth: auth, email: user.email ?? '');
            }
            return HomeScreen(user: profile, auth: auth);
          },
        );
      },
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class _NoProfile extends StatelessWidget {
  const _NoProfile({required this.auth, required this.email});

  final AuthService auth;
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
                onPressed: auth.signOut,
                child: const Text('লগআউট'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
