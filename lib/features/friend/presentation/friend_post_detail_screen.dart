import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/constants/app_colors.dart';
import '../data/friend_repository.dart';
import '../domain/friend_post_model.dart';

/// 好友动态详情 + 评论区
///
/// 对应桌面端 `view/fried/qt_fried_msg.py#OpenComment` 等
class FriendPostDetailScreen extends ConsumerStatefulWidget {
  final String postId;
  const FriendPostDetailScreen({super.key, required this.postId});

  @override
  ConsumerState<FriendPostDetailScreen> createState() =>
      _FriendPostDetailScreenState();
}

class _FriendPostDetailScreenState
    extends ConsumerState<FriendPostDetailScreen> {
  final TextEditingController _commentCtrl = TextEditingController();
  final ScrollController _scroll = ScrollController();
  List<FriendComment> _comments = [];
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list =
          await ref.read(friendRepositoryProvider).getComments(widget.postId);
      if (!mounted) return;
      setState(() {
        _comments = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _send() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ref
          .read(friendRepositoryProvider)
          .sendComment(widget.postId, text);
      if (!mounted) return;
      _commentCtrl.clear();
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('发送失败: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _like(FriendComment c) async {
    try {
      await ref
          .read(friendRepositoryProvider)
          .likeComment(widget.postId, c.id);
    } catch (_) {
      // 桌面端允许乐观更新；移动端同样忽略网络错误
    }
    setState(() {
      final i = _comments.indexOf(c);
      if (i >= 0) {
        _comments[i] = FriendComment(
          id: c.id,
          content: c.content,
          user: c.user,
          totalLikes: c.liked ? c.totalLikes - 1 : c.totalLikes + 1,
          liked: !c.liked,
          createdAt: c.createdAt,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('动态详情'),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _ErrorState(message: _error!, onRetry: _load)
                    : _comments.isEmpty
                        ? Center(
                            child: Text(
                              '还没有评论',
                              style:
                                  TextStyle(color: AppColors.secondaryText),
                            ),
                          )
                        : ListView.builder(
                            controller: _scroll,
                            padding: const EdgeInsets.all(12),
                            itemCount: _comments.length,
                            itemBuilder: (context, i) =>
                                _CommentTile(
                              comment: _comments[i],
                              onLike: () => _like(_comments[i]),
                            ),
                          ),
          ),
          const Divider(height: 1),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentCtrl,
                      maxLines: 3,
                      minLines: 1,
                      decoration: const InputDecoration(
                        hintText: '说点什么…',
                        prefixIcon: Icon(Icons.chat_bubble_outline),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _sending ? null : _send,
                    child: _sending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('发送'),
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

class _CommentTile extends StatelessWidget {
  final FriendComment comment;
  final VoidCallback onLike;
  const _CommentTile({required this.comment, required this.onLike});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.darkCard,
            backgroundImage: comment.user.avatar.isNotEmpty
                ? CachedNetworkImageProvider(comment.user.avatar)
                : null,
            child: comment.user.avatar.isEmpty
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
                      comment.user.name.isEmpty ? '匿名' : comment.user.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (comment.user.title.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          comment.user.title,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      _formatDate(comment.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment.content),
                const SizedBox(height: 4),
                InkWell(
                  onTap: onLike,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        comment.liked
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 14,
                        color: comment.liked ? Colors.pink : null,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${comment.totalLikes}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime? d) {
    if (d == null) return '';
    return DateFormat('MM-dd HH:mm').format(d.toLocal());
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              '加载失败: $message',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.secondaryText),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}
