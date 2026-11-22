import 'package:material_ui/material_ui.dart';

import '../models/app_user.dart';
import '../models/user_role.dart';
import '../services/auth_service.dart';

/// রোল অনুযায়ী ফিচার টাইল দেখানো হোম স্ক্রিন।
/// প্রতিটি টাইল পরবর্তী ধাপে আসল স্ক্রিনের সাথে যুক্ত হবে।
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.user, required this.auth});

  final AppUser user;
  final AuthService auth;

  List<_Feature> _featuresFor(UserRole role) => [
    const _Feature(Icons.campaign_outlined, 'নোটিশ'),
    if (role.canPublishNotices)
      const _Feature(Icons.warning_amber_rounded, 'জরুরি সতর্কবার্তা'),
    const _Feature(Icons.chat_bubble_outline, 'চ্যাট'),
    const _Feature(Icons.task_alt, 'টাস্ক'),
    const _Feature(Icons.how_to_vote_outlined, 'পোল'),
    const _Feature(Icons.event_outlined, 'মিটিং'),
    const _Feature(Icons.beach_access_outlined, 'ছুটির আবেদন'),
    const _Feature(Icons.folder_outlined, 'ডকুমেন্ট'),
    if (role.canViewExecutiveDashboard)
      const _Feature(Icons.insights_outlined, 'এক্সিকিউটিভ ড্যাশবোর্ড'),
    if (role.canManageUsers)
      const _Feature(Icons.admin_panel_settings_outlined, 'অ্যাডমিন প্যানেল'),
  ];

  @override
  Widget build(BuildContext context) {
    final features = _featuresFor(user.role);
    return Scaffold(
      appBar: AppBar(
        title: const Text('HPS Connect'),
        actions: [
          IconButton(
            tooltip: 'লগআউট',
            icon: const Icon(Icons.logout),
            onPressed: auth.signOut,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(user.name.isEmpty ? user.email : user.name),
              subtitle: Text(user.role.labelBn),
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              for (final f in features)
                Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${f.label}: শীঘ্রই আসছে')),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(f.icon, size: 32),
                        const SizedBox(height: 8),
                        Text(f.label, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Feature {
  const _Feature(this.icon, this.label);
  final IconData icon;
  final String label;
}
