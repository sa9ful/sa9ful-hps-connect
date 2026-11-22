import 'package:material_ui/material_ui.dart';

import '../app_state.dart';
import '../data/models.dart';
import '../models/app_user.dart';
import '../models/user_role.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'directory_screen.dart';
import 'meetings_screen.dart';
import 'notice_board_screen.dart';
import 'side_menu.dart';
import 'tasks_screen.dart';

/// প্রিন্সিপাল ও সুপার অ্যাডমিনের মূল স্ক্রিন (Dashboard/People/Reports/More)।
class PrincipalShell extends StatefulWidget {
  const PrincipalShell({super.key, required this.user, required this.role});
  final AppUser user;
  final UserRole role;

  @override
  State<PrincipalShell> createState() => _PrincipalShellState();
}

class _PrincipalShellState extends State<PrincipalShell> {
  final _scaffold = GlobalKey<ScaffoldState>();
  int _tab = 0;

  void _goTab(int i) {
    if (i == 3) {
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
            PrincipalDashboard(
              user: widget.user,
              role: widget.role,
              onMenu: () => _scaffold.currentState?.openDrawer(),
            ),
            DirectoryScreen(title: 'People', onBack: home),
            ComingSoonScreen(title: 'Reports', icon: Icons.bar_chart),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: _goTab,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'People',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Reports',
            ),
            NavigationDestination(icon: Icon(Icons.more_horiz), label: 'More'),
          ],
        ),
      ),
    );
  }
}

class PrincipalDashboard extends StatelessWidget {
  const PrincipalDashboard({
    super.key,
    required this.user,
    required this.role,
    required this.onMenu,
  });

  final AppUser user;
  final UserRole role;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final backend = AppScope.backendOf(context);
    void push(Widget page) =>
        Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => page));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.menu), onPressed: onMenu),
        title: Text(
          role == UserRole.principal
              ? 'Principal Dashboard'
              : 'Admin Dashboard',
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: HpsColors.headerGradient),
        ),
      ),
      body: StreamBuilder<DashboardStats>(
        stream: backend.stats(),
        builder: (context, snap) {
          final s = snap.data ?? const DashboardStats();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      InitialsAvatar(name: user.displayName, radius: 30),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              role.labelEn,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Text('Heritage Public School'),
                            const Text(
                              'Faridpur',
                              style: TextStyle(color: HpsColors.blue),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.insights, color: HpsColors.blue),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.3,
                children: [
                  _Stat(
                    icon: Icons.groups,
                    label: 'Total Users',
                    value: s.totalUsers,
                  ),
                  _Stat(
                    icon: Icons.school,
                    label: 'Teachers',
                    value: s.teachers,
                    color: const Color(0xFF7C4DFF),
                  ),
                  _Stat(
                    icon: Icons.group,
                    label: 'Staff',
                    value: s.staff,
                    color: HpsColors.warning,
                  ),
                  _Stat(
                    icon: Icons.layers,
                    label: 'Departments',
                    value: s.departments,
                    color: const Color(0xFF5C6BC0),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _Action(
                      icon: Icons.send,
                      label: 'Send Notice',
                      onTap: () => push(PublishNoticeScreen(role: role)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Action(
                      icon: Icons.edit_calendar,
                      label: 'Schedule Meeting',
                      onTap: () => showScheduleMeetingSheet(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Action(
                      icon: Icons.add_task,
                      label: 'Assign Task',
                      onTap: () => showAssignTaskSheet(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 6, 16, 4),
                        child: Text(
                          'Quick Overview',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      _Overview(
                        icon: Icons.notifications_none,
                        label: 'Unread Notices',
                        count: s.unreadNotices,
                        color: HpsColors.important,
                        onTap: () => push(NoticeBoardScreen(role: role)),
                      ),
                      _Overview(
                        icon: Icons.calendar_today,
                        label: 'Upcoming Meetings',
                        count: s.upcomingMeetings,
                        color: const Color(0xFFFB8C00),
                        onTap: () => push(MeetingsScreen(role: role)),
                      ),
                      _Overview(
                        icon: Icons.check_box_outlined,
                        label: 'Pending Tasks',
                        count: s.pendingTasks,
                        color: HpsColors.warning,
                        onTap: () => push(TasksScreen(role: role)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.label,
    required this.value,
    this.color = HpsColors.blue,
  });
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Icon(icon, size: 34, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    '$value',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: FeatureTile(icon: icon, label: label, onTap: onTap),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int count;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(icon),
      title: Text(label, style: const TextStyle(fontSize: 15)),
      trailing: CountBadge(count, color: color),
      onTap: onTap,
    );
  }
}
