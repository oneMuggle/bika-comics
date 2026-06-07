import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/storage/settings_storage.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/widgets/cached_image.dart';
import '../data/chat_repository.dart';
import '../domain/chat_model.dart';

/// 聊天室 WebSocket 视图
///
/// 对应桌面端 `view/chat_new/chat_new_room_widget.py` + `chat_new_websocket.py`
/// - 进入页面：建立 WebSocket 连接（`?token=...&room=...`）
/// - 监听消息：
///   - TEXT_MESSAGE -> 文字
///   - IMAGE_MESSAGE -> 图片
///   - CONNECTED -> 不显示
///   - INITIAL_MESSAGES -> 历史消息（data.messages[]）
///   - UPDATE_ROOM_ONLINE_USERS_COUNT_ACTION -> 更新在线人数
/// - 离开页面：关闭 WebSocket
class ChatRoomScreen extends ConsumerStatefulWidget {
  final String roomId;
  final String roomName;
  const ChatRoomScreen({
    super.key,
    required this.roomId,
    required this.roomName,
  });

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<ChatMessage> _messages = [];
  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  int _onlineCount = 0;
  bool _connected = false;
  int _sendAction = 0; // 0 = Ctrl+Enter 发送, 1 = Enter 发送
  String? _replyToId;
  String? _replyToName;
  String? _replyToText;
  bool _showEmoji = false;
  static const List<String> _emojis = [
    '😀', '😂', '🤣', '😊', '😍', '😘', '😎', '🤩',
    '😢', '😭', '😡', '😱', '🥺', '😴', '🤔', '🙄',
    '👍', '👎', '👏', '🙏', '💪', '👌', '✌️', '🤝',
    '❤️', '💔', '💖', '💯', '🔥', '✨', '🎉', '🎊',
    '🌹', '🌸', '🌺', '🍀', '🌙', '⭐', '☀️', '🌈',
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _connect();
  }

  Future<void> _loadSettings() async {
    final s = ref.read(settingsStorageProvider);
    final v = await s.getChatSendAction();
    if (!mounted) return;
    setState(() => _sendAction = v);
  }

  Future<void> _setSendAction(int v) async {
    final s = ref.read(settingsStorageProvider);
    await s.setChatSendAction(v);
    setState(() => _sendAction = v);
  }

  Future<void> _connect() async {
    final repo = ref.read(chatRepositoryProvider);
    try {
      final result = await repo.connect(roomId: widget.roomId);
      if (!mounted) return;
      _channel = result.channel;
      _sub = result.stream.listen(_onMessage, onError: (e) {
        if (!mounted) return;
        setState(() => _connected = false);
      }, onDone: () {
        if (!mounted) return;
        setState(() => _connected = false);
      });
      setState(() => _connected = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('连接失败: $e')),
      );
    }
  }

  void _onMessage(dynamic raw) {
    if (raw is! Map) return;
    final json = raw.cast<String, dynamic>();
    final type = json['type']?.toString() ?? '';
    if (type == 'INITIAL_MESSAGES') {
      final data = json['data'] is Map
          ? (json['data'] as Map).cast<String, dynamic>()
          : <String, dynamic>{};
      final list = (data['messages'] as List? ?? [])
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      setState(() {
        // 在已有消息前面插入历史
        _messages.insertAll(0, list.reversed);
      });
      return;
    }
    if (type == 'CONNECTED') return;
    if (type == 'UPDATE_ROOM_ONLINE_USERS_COUNT_ACTION') {
      final data = json['data'] is Map
          ? (json['data'] as Map).cast<String, dynamic>()
          : <String, dynamic>{};
      final count = data['onlineCount'];
      if (count is int && mounted) {
        setState(() => _onlineCount = count);
      }
      return;
    }
    if (type == 'TEXT_MESSAGE' || type == 'IMAGE_MESSAGE') {
      final msg = ChatMessage.fromJson(json);
      if (!mounted) return;
      setState(() => _messages.add(msg));
      _autoScroll();
      return;
    }
  }

  void _autoScroll() {
    if (!_scroll.hasClients) return;
    Future.delayed(const Duration(milliseconds: 50), () {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();
    try {
      await ref.read(chatRepositoryProvider).sendText(
            roomId: widget.roomId,
            message: text,
            replyId: _replyToId,
          );
      setState(() {
        _replyToId = null;
        _replyToName = null;
        _replyToText = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('发送失败: $e')),
      );
    }
  }

  void _insertEmoji(String e) {
    final old = _input.text;
    final sel = _input.selection;
    final start = sel.start >= 0 ? sel.start : old.length;
    final end = sel.end >= 0 ? sel.end : old.length;
    final newText = old.replaceRange(start, end, e);
    _input.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + e.length),
    );
  }

  void _setReply(ChatMessage m) {
    setState(() {
      _replyToId = m.id;
      _replyToName = m.profile?.name ?? '匿名';
      _replyToText = m.text ?? m.caption ?? '[图片]';
    });
  }

  void _cancelReply() {
    setState(() {
      _replyToId = null;
      _replyToName = null;
      _replyToText = null;
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _channel?.sink.close();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(widget.roomName, style: const TextStyle(fontSize: 16)),
            Text(
              _connected
                  ? '在线 $_onlineCount'
                  : '连接中…',
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (v) {
              if (v == 'enter') _setSendAction(1);
              if (v == 'ctrl') _setSendAction(0);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'enter',
                child: Row(
                  children: [
                    Icon(_sendAction == 1
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off),
                    const SizedBox(width: 8),
                    const Text('按 Enter 发送'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'ctrl',
                child: Row(
                  children: [
                    Icon(_sendAction == 0
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off),
                    const SizedBox(width: 8),
                    const Text('按 Ctrl+Enter 发送'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // ============ 消息列表 ============
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Text(
                      _connected ? '暂无消息' : '正在连接聊天室…',
                      style: TextStyle(color: AppColors.secondaryText),
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(8),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) {
                      final m = _messages[i];
                      return _MessageTile(
                        message: m,
                        onReply: () => _setReply(m),
                      );
                    },
                  ),
          ),

          // ============ 回复预览 ============
          if (_replyToId != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: AppColors.darkCard.withValues(alpha: 0.3),
              child: Row(
                children: [
                  const Icon(Icons.reply, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '回复 $_replyToName: $_replyToText',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: _cancelReply,
                    tooltip: '取消回复',
                  ),
                ],
              ),
            ),

          // ============ 表情面板 ============
          if (_showEmoji)
            Container(
              height: 200,
              padding: const EdgeInsets.all(8),
              child: GridView.builder(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemCount: _emojis.length,
                itemBuilder: (context, i) {
                  return InkWell(
                    onTap: () => _insertEmoji(_emojis[i]),
                    child: Center(
                      child: Text(
                        _emojis[i],
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  );
                },
              ),
            ),

          // ============ 输入区 ============
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(_showEmoji
                        ? Icons.keyboard
                        : Icons.emoji_emotions_outlined),
                    onPressed: () =>
                        setState(() => _showEmoji = !_showEmoji),
                    tooltip: '表情',
                  ),
                  Expanded(
                    child: TextField(
                      controller: _input,
                      maxLines: 3,
                      minLines: 1,
                      decoration: const InputDecoration(
                        hintText: '说点什么…',
                      ),
                      onSubmitted: (_) {
                        if (_sendAction == 1) _send();
                      },
                      onTap: () {
                        if (_showEmoji) setState(() => _showEmoji = false);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _send,
                    child: const Text('发送'),
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

class _MessageTile extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback onReply;
  const _MessageTile({required this.message, required this.onReply});

  @override
  Widget build(BuildContext context) {
    final profile = message.profile;
    final name = profile?.name ?? '匿名';
    final time = message.createdAt != null
        ? DateFormat('HH:mm').format(message.createdAt!.toLocal())
        : '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.darkCard,
            backgroundImage:
                (profile?.avatarUrl ?? '').isNotEmpty
                    ? CachedNetworkImageProvider(profile!.avatarUrl)
                    : null,
            child: (profile?.avatarUrl ?? '').isEmpty
                ? const Icon(Icons.person, color: Colors.white54, size: 18)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (profile?.title.isNotEmpty ?? false) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          profile!.title,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 6),
                    Text(
                      'LV${profile?.level ?? 0}',
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 11,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (message.text != null)
                  Text(message.text!)
                else if (message.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedImage(
                      imageUrl: message.imageUrl!,
                      width: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                if (message.reply != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.darkCard.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(4),
                      border: Border(
                        left: BorderSide(
                          color: AppColors.primary,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Text(
                      '回复 ${message.reply!.name ?? "匿名"}: '
                      '${message.reply!.message ?? "[图片]"}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 2),
                InkWell(
                  onTap: onReply,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '回复',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
