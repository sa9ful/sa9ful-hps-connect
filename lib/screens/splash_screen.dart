import 'package:material_ui/material_ui.dart';

import '../theme.dart';
import '../widgets/common.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: HpsColors.headerGradient),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              const SchoolLogo(size: 150),
              const SizedBox(height: 28),
              const Text(
                'HPS CONNECT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Connecting People,\nBuilding Together',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const Spacer(flex: 3),
              // অনুমান: ডিজাইনের স্কুল ভবনের ছবি নেই, তাই আইকন ব্যবহার।
              Icon(
                Icons.apartment_rounded,
                size: 90,
                color: Colors.white.withValues(alpha: 0.85),
              ),
              const SizedBox(height: 8),
              Text(
                'Heritage Public School, Faridpur',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
