import 'package:material_ui/material_ui.dart';

import '../app_state.dart';
import '../models/app_user.dart';
import '../widgets/common.dart';

class DirectoryScreen extends StatefulWidget {
  const DirectoryScreen({super.key, this.title = 'Directory', this.onBack});
  final String title;
  final VoidCallback? onBack;

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  String _q = '';
  late final Stream<List<AppUser>> _stream = AppScope.backendOf(context)
      .directory();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: widget.onBack ?? () => Navigator.maybePop(context),
        ),
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by name',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _q = v.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<AppUser>>(
              stream: _stream,
              builder: (context, snap) {
                final list = snap.data
                    ?.where((u) => u.displayName.toLowerCase().contains(_q))
                    .toList();
                return AsyncList<AppUser>(
                  snapshot: list == null
                      ? snap
                      : AsyncSnapshot.withData(ConnectionState.active, list),
                  emptyText: 'কাউকে পাওয়া যায়নি',
                  builder: (items) => ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final u = items[i];
                      return ListTile(
                        leading: InitialsAvatar(
                          name: u.displayName,
                          radius: 22,
                        ),
                        title: Text(
                          u.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          [
                            u.role.labelEn,
                            if (u.department != null) u.department,
                          ].join(' • '),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
