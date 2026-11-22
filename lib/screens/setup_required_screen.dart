import 'package:material_ui/material_ui.dart';

/// google-services.json ছাড়া বিল্ড হলে এই স্ক্রিন দেখায়।
class SetupRequiredScreen extends StatelessWidget {
  const SetupRequiredScreen({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.settings_suggest, size: 56),
              const SizedBox(height: 16),
              Text(
                'Firebase সেটআপ বাকি',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              const Text(
                'এই APK-তে Firebase কনফিগারেশন (google-services.json) যোগ করা হয়নি। '
                'GitHub Secrets-এ GOOGLE_SERVICES_JSON_BASE64 যোগ করে আবার বিল্ড করুন। '
                'বিস্তারিত README-তে আছে।',
              ),
              const SizedBox(height: 12),
              Text('$error', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
