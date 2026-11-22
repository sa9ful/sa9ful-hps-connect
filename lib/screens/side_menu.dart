import 'package:material_ui/material_ui.dart';

import '../app_state.dart';
import '../models/app_user.dart';
import '../models/user_role.dart';
import '../theme.dart';
import '../widgets/common.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({super.key, required this.user, required this.role});
  final AppUser user;
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    void open(String title, IconData icon) {
      Navigator.of(context)
        ..pop()
        ..push(
          MaterialPageRoute<void>(
            builder: (_) => ComingSoonScreen(title: title, icon: icon),
          ),
        );
    }

    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: const BoxDecoration(gradient: HpsColors.headerGradient),
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.paddingOf(context).top + 24,
              20,
              24,
            ),
            child: Row(
              children: [
                InitialsAvatar(
                  name: user.displayName,
                  radius: 30,
                  color: Colors.white24,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        role.labelEn,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _item(
            Icons.person_outline,
            'My Profile',
            () => open('My Profile', Icons.person_outline),
          ),
          _item(
            Icons.apartment_outlined,
            'My Department',
            () => open('My Department', Icons.apartment_outlined),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_none),
            title: const Text('Notifications'),
            trailing: const CountBadge(5),
            onTap: () => open('Notifications', Icons.notifications_none),
          ),
          _item(
            Icons.settings_outlined,
            'Settings',
            () => open('Settings', Icons.settings_outlined),
          ),
          _item(
            Icons.help_outline,
            'Help & Support',
            () => open('Help & Support', Icons.help_outline),
          ),
          _item(Icons.info_outline, 'About HPS CONNECT', () {
            Navigator.pop(context);
            showAboutDialog(
              context: context,
              applicationName: 'HPS CONNECT',
              applicationVersion: '1.0.0',
              applicationIcon: const SchoolLogo(size: 48),
              children: const [
                Text(
                  'Heritage Public School, Faridpur\nConnecting People, Building Together',
                ),
              ],
            );
          }),
          if (user.allowedRoles.length > 1)
            _item(Icons.swap_horiz, 'Switch Role', () {
              Navigator.pop(context);
              state.selectRole(null);
            }),
          const Divider(indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.logout, color: HpsColors.important),
            title: const Text(
              'Logout',
              style: TextStyle(
                color: HpsColors.important,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              state.backend.signOut();
            },
          ),
        ],
      ),
    );
  }

  Widget _item(IconData icon, String label, VoidCallback onTap) =>
      ListTile(leading: Icon(icon), title: Text(label), onTap: onTap);
}
