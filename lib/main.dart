import 'package:firebase_core/firebase_core.dart';
import 'package:material_ui/material_ui.dart';

import 'screens/auth_gate.dart';
import 'screens/setup_required_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Object? firebaseError;
  try {
    // Android-এ কনফিগ আসে android/app/google-services.json থেকে।
    await Firebase.initializeApp();
  } catch (e) {
    firebaseError = e;
    debugPrint('Firebase চালু করা যায়নি: $e');
  }

  runApp(HpsConnectApp(firebaseError: firebaseError));
}

class HpsConnectApp extends StatelessWidget {
  const HpsConnectApp({super.key, this.firebaseError});

  final Object? firebaseError;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HPS Connect',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: firebaseError == null
          ? const AuthGate()
          : SetupRequiredScreen(error: firebaseError!),
    );
  }
}
