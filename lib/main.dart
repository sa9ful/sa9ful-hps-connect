import 'package:firebase_core/firebase_core.dart';
import 'package:material_ui/material_ui.dart';

import 'app_state.dart';
import 'data/backend.dart';
import 'data/demo_backend.dart';
import 'data/firebase_backend.dart';
import 'screens/auth_gate.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Backend backend;
  try {
    // Android-এ কনফিগ আসে android/app/google-services.json থেকে।
    await Firebase.initializeApp();
    backend = FirebaseBackend();
  } catch (e) {
    // google-services.json ছাড়া বিল্ড: নমুনা ডেটা দিয়ে ডেমো মোড।
    debugPrint('Firebase চালু করা যায়নি, ডেমো মোড: $e');
    backend = DemoBackend();
  }

  runApp(HpsConnectApp(backend: backend));
}

class HpsConnectApp extends StatefulWidget {
  const HpsConnectApp({super.key, required this.backend, this.splashDuration});

  final Backend backend;
  final Duration? splashDuration;

  @override
  State<HpsConnectApp> createState() => _HpsConnectAppState();
}

class _HpsConnectAppState extends State<HpsConnectApp> {
  late final AppState _state = AppState(widget.backend);

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: _state,
      child: MaterialApp(
        title: 'HPS Connect',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: widget.splashDuration == null
            ? const AuthGate()
            : AuthGate(splashDuration: widget.splashDuration!),
      ),
    );
  }
}
