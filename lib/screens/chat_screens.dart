import 'package:material_ui/material_ui.dart';

import '../app_state.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets/common.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key, this.onBack});
  final VoidCallback? onBack;

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  int _tab = 0;
  late final Stream<List<ChatThread>> _stream = AppScope.backendOf(context)
      .chats();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: widget.onBack ?? () => Navigator.maybePop(context),
        ),
        title: const Text('Chat'),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'chat-fab',
        tooltip: 'New chat',
        // অনুমান: নতুন চ্যাট/গ্রুপ খোলার স্ক্রিন পরের ধাপে।
        onPressed: () => showSnack(context, 'নতুন চ্যাট শীঘ্রই আসছে'),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          PillTabs(
            labels: const ['All', 'Personal', 'Group'],
            selected: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
          Expanded(
            child: StreamBuilder<List<ChatThread>>(
              stream: _stream,
              builder: (context, snap) {
                final filtered = snap.data
                    ?.where((c) => _tab == 0 || (_tab == 2) == c.isGroup)
                    .toList();
                return AsyncList<ChatThread>(
                  snapshot: filtered == null
                      ? snap
                      : AsyncSnapshot.withData(
                          ConnectionState.active,
                          filtered,
                        ),
                  emptyText: 'কোনো চ্যাট নেই',
                  builder: (items) => ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: items.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, indent: 76),
                    itemBuilder: (_, i) => _ChatTile(chat: items[i]),
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

class _ChatTile extends StatelessWidget {
  const _ChatTile({required this.chat});
  final ChatThread chat;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: InitialsAvatar(
        name: chat.name,
        radius: 24,
        color: HpsColors
            .avatarColors[chat.colorIndex % HpsColors.avatarColors.length],
        icon: chat.isGroup ? Icons.groups : null,
      ),
      title: Text(
        chat.name,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        chat.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(fmtChatTime(chat.lastAt), style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          if (chat.unread > 0)
            CircleAvatar(
              radius: 10,
              backgroundColor: HpsColors.important,
              child: Text(
                '${chat.unread}',
                style: const TextStyle(fontSize: 11, color: Colors.white),
              ),
            ),
        ],
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => ChatRoomScreen(chat: chat)),
      ),
    );
  }
}

class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({super.key, required this.chat});
  final ChatThread chat;

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _text = TextEditingController();
  late final _backend = AppScope.backendOf(context);
  late final Stream<List<ChatMessage>> _stream = _backend.messages(
    widget.chat.id,
  );

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final t = _text.text.trim();
    if (t.isEmpty) return;
    _text.clear();
    try {
      await _backend.sendMessage(widget.chat.id, t);
    } catch (e) {
      if (mounted) showSnack(context, 'পাঠানো যায়নি: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = _backend.user?.uid;
    return Scaffold(
      appBar: AppBar(title: Text(widget.chat.name)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _stream,
              builder: (context, snap) => AsyncList<ChatMessage>(
                snapshot: snap,
                emptyText: 'প্রথম বার্তা লিখুন',
                builder: (items) => ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final m = items[i];
                    final mine = m.senderId == me;
                    return Align(
                      alignment: mine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: mine ? HpsColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 3),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!mine && widget.chat.isGroup)
                              Text(
                                m.senderName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: HpsColors.blue,
                                ),
                              ),
                            Text(
                              m.text,
                              style: TextStyle(
                                color: mine ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              fmtTime(m.sentAt),
                              style: TextStyle(
                                fontSize: 10,
                                color: mine ? Colors.white70 : Colors.black45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _text,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Type a message',
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filled(
                    onPressed: _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
