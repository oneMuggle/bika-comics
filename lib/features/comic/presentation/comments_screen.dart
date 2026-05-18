import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/constants/app_colors.dart';
import '../data/comic_repository.dart';
import '../domain/comment_model.dart';

/// 评论 Provider
final commentsProvider = FutureProvider.family<List<Comment>, String>((ref, comicId) async {
  final repo = ref.read(comicRepositoryProvider);
  return repo.getComments(comicId);
});

/// 评论页
class CommentsScreen extends ConsumerStatefulWidget {
  final String comicId;

  const CommentsScreen({super.key, required this.comicId});

  @override
  ConsumerState<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends ConsumerState<CommentsScreen> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  bool _isSending = false;
  String? _replyToId;
  String? _replyToName;

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final content = _textController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSending = true);
    try {
      final repo = ref.read(comicRepositoryProvider);
      await repo.sendComment(widget.comicId, content, parentId: _replyToId);
      _textController.clear();
      setState(() {
        _replyToId = null;
        _replyToName = null;
      });
      ref.invalidate(commentsProvider(widget.comicId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发送失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _likeComment(String commentId) async {
    try {
      final repo = ref.read(comicRepositoryProvider);
      await repo.likeComment(commentId);
      ref.invalidate(commentsProvider(widget.comicId));
    } catch (e) {
      // ignore
    }
  }

  Future<void> _reportComment(String commentId) async {
    try {
      final repo = ref.read(comicRepositoryProvider);
      await repo.reportComment(commentId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('举报成功')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('举报失败: $e')),
        );
      }
    }
  }

  void _setReplyTo(String id, String name) {
    setState(() {
      _replyToId = id;
      _replyToName = name;
    });
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final asyncComments = ref.watch(commentsProvider(widget.comicId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('评论'),
      ),
      body: Column(
        children: [
          Expanded(
            child: asyncComments.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text('加载失败: $e'),
                    FilledButton(
                      onPressed: () => ref.invalidate(commentsProvider(widget.comicId)),
                      child: const Text('重试'),
                    ),
                  ],
                ),
              ),
              data: (comments) => comments.isEmpty
                  ? const Center(child: Text('暂无评论，快来抢沙发~'))
                  : RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(commentsProvider(widget.comicId));
                      },
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          return _CommentTile(
                            comment: comments[index],
                            onLike: () => _likeComment(comments[index].id),
                            onReply: (name) =>
                                _setReplyTo(comments[index].id, name),
                            onReport: () =>
                                _reportComment(comments[index].id),
                          );
                        },
                      ),
                    ),
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_replyToName != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Text(
                    '回复 @$_replyToName',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _replyToId = null;
                        _replyToName = null;
                      });
                    },
                    child: const Icon(Icons.close, size: 16),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText:
                        _replyToName == null ? '说点什么...' : '回复 @$_replyToName',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: 3,
                  minLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _isSending ? null : _sendComment,
                icon: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 单条评论
class _CommentTile extends StatelessWidget {
  final Comment comment;
  final VoidCallback onLike;
  final void Function(String name) onReply;
  final VoidCallback onReport;

  const _CommentTile({
    required this.comment,
    required this.onLike,
    required this.onReply,
    required this.onReport,
  });

  void _showMoreMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.flag),
              title: const Text('举报'),
              onTap: () {
                Navigator.pop(ctx);
                onReport();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头像
          ClipOval(
            child: comment.userAvatar.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: comment.userAvatar,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 40,
                      height: 40,
                      color: AppColors.darkCard,
                      child: const Icon(Icons.person, size: 24),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 40,
                      height: 40,
                      color: AppColors.darkCard,
                      child: const Icon(Icons.person, size: 24),
                    ),
                  )
                : Container(
                    width: 40,
                    height: 40,
                    color: AppColors.darkCard,
                    child: const Icon(Icons.person, size: 24),
                  ),
          ),
          const SizedBox(width: 12),
          // 内容
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.userName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Text(
                      _formatTime(comment.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(150),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment.content),
                const SizedBox(height: 8),
                Row(
                  children: [
                    GestureDetector(
                      onTap: onLike,
                      child: Row(
                        children: [
                          Icon(
                            comment.isLiked
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 18,
                            color: comment.isLiked
                                ? AppColors.error
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withAlpha(150),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${comment.likeCount}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withAlpha(150),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () => onReply(comment.userName),
                      child: Row(
                        children: [
                          Icon(
                            Icons.reply,
                            size: 18,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withAlpha(150),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '回复',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withAlpha(150),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (comment.replyCount > 0) ...[
                      const SizedBox(width: 16),
                      Text(
                        '${comment.replyCount} 条回复',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _showMoreMenu(context),
                      child: Icon(
                        Icons.more_vert,
                        size: 18,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(150),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String timeStr) {
    try {
      final dt = DateTime.parse(timeStr);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inDays > 0) return '${diff.inDays}天前';
      if (diff.inHours > 0) return '${diff.inHours}小时前';
      if (diff.inMinutes > 0) return '${diff.inMinutes}分钟前';
      return '刚刚';
    } catch (_) {
      return timeStr;
    }
  }
}
