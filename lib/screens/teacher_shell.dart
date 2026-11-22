import 'package:material_ui/material_ui.dart';

import '../app_state.dart';
import '../models/app_user.dart';
import '../models/user_role.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'chat_screens.dart';
import 'directory_screen.dart';
import 'leave_application_screen.dart';
import 'meetings_screen.dart';
import 'notice_board_screen.dart';
import 'side_menu.dart';
import 'tasks_screen.dart';

/// শিক্ষক/স্টাফ ও সেকশন ইনচার্জদের মূল স্ক্রিন (নিচে Home/Chat/Notice/Tasks/More)।
class TeacherShell extends StatefulWidget {
  const TeacherShell({super.key, required this.user, required this.role});
  final AppUser user;
  final UserRole role;

  @override
  State<TeacherShell> createState() => _TeacherShellState();
}

class _TeacherShellState extends State<TeacherShell> {
  final _scaffold = GlobalKey<ScaffoldState>();
  int _tab = 0;

  void _goTab(int i) {
    if (i == 4) {
      _scaffold.currentState?.openDrawer();
      return;
    }
    setState(() => _tab = i);
  }

  @override
  Widget build(BuildContext context) {
    void home() => setState(() => _tab = 0);
    return PopScope(
      canPop: _tab == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) home();
      },
      child: Scaffold(
        key: _scaffold,
        drawer: SideMenu(user: widget.user, role: widget.role),
        body: IndexedStack(
          index: _tab,
          children: [
            TeacherHome(
              user: widget.user,
              role: widget.role,
              onMenu: () => _scaffold.currentState?.openDrawer(),
              onTab: _goTab,
            ),
            ChatListScreen(onBack: home),
            NoticeBoardScreen(role: widget.role, onBack: home),
            TasksScreen(role: widget.role, onBack: home),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: _goTab,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble),
              label: 'Chat',
            ),
            NavigationDestination(
              icon: Icon(Icons.notifications_none),
              selectedIcon: Icon(Icons.notifications),
              label: 'Notice',
            ),
            NavigationDestination(
              icon: Icon(Icons.check_box_outlined),
              selectedIcon: Icon(Icons.check_box),
              label: 'Tasks',
            ),
            NavigationDestination(icon: Icon(Icons.more_horiz), label: 'More'),
          ],
        ),
      ),
    );
  }
}

class TeacherHome extends StatelessWidget {
  const TeacherHome({
    super.key,
    required this.user,
    required this.role,
    required this.onMenu,
    required this.onTab,
  });

  final AppUser user;
  final UserRole role;
  final VoidCallback onMenu;
  final ValueChanged<int> onTab;

  @override
  Widget build(BuildContext context) {
    final backend = AppScope.backendOf(context);
    void push(Widget page) =>
        Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => page));
    void soon(String t, IconData i) =>
        push(ComingSoonScreen(title: t, icon: i));

    return Column(
      children: [
        _Header(user: user, role: role, onMenu: onMenu, onBell: () => onTab(2)),
        Expanded(
          child: StreamBuilder(
            stream: backend.notices(),
            builder: (context, snap) {
              final hasNotices = (snap.data ?? const []).isNotEmpty;
              return GridView.count(
                padding: const EdgeInsets.all(16),
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  FeatureTile(
                    icon: Icons.campaign,
                    label: 'Notice Board',
                    badge: hasNotices,
                    onTap: () => onTab(2),
                  ),
                  FeatureTile(
                    icon: Icons.forum,
                    label: 'Messages',
                    onTap: () => onTab(1),
                  ),
                  FeatureTile(
                    icon: Icons.calendar_month,
                    label: 'Meetings',
                    onTap: () => push(MeetingsScreen(role: role)),
                  ),
                  FeatureTile(
                    icon: Icons.check_box,
                    label: 'Tasks',
                    onTap: () => onTab(3),
                  ),
                  FeatureTile(
                    icon: Icons.assignment,
                    label: 'Leave Application',
                    onTap: () => push(const LeaveApplicationScreen()),
                  ),
                  FeatureTile(
                    icon: Icons.folder,
                    label: 'Documents',
                    onTap: () => soon('Documents', Icons.folder),
                  ),
                  FeatureTile(
                    icon: Icons.event,
                    label: 'Events',
                    onTap: () => soon('Events', Icons.event),
                  ),
                  FeatureTile(
                    icon: Icons.bar_chart,
                    label: 'Polls',
                    onTap: () => soon('Polls', Icons.bar_chart),
                  ),
                  FeatureTile(
                    icon: Icons.groups,
                    label: 'Directory',
                    onTap: () => push(const DirectoryScreen()),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.user,
    required this.role,
    required this.onMenu,
    required this.onBell,
  });

  final AppUser user;
  final UserRole role;
  final VoidCallback onMenu;
  final VoidCallback onBell;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: HpsColors.headerGradient,
        borderRadius: BorderRadius.only(bottomRight: Radius.circular(36)),
      ),
      padding: EdgeInsets.fromLTRB(
        8,
        MediaQuery.paddingOf(context).top,
        16,
        22,
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onMenu,
                icon: const Icon(Icons.menu, color: Colors.white),
              ),
              const Expanded(
                child: Text(
                  'HPS CONNECT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: onBell,
                icon: const Badge(
                  smallSize: 9,
                  child: Icon(Icons.notifications_none, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: InitialsAvatar(
                  name: user.displayName,
                  radius: 30,
                  color: HpsColors.light,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Assalamu Alaikum',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    Text(
                      user.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      role.labelEn,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
