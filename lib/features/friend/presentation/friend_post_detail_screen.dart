import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/constants/app_colors.dart';
import '../../../shared/widgets/cached_image.dart';
import '../data/friend_repository.dart';
import '../domain/friend_post_model.dart';

/// 好友动态详情 + 评论区
///
/// 对应桌面端 `view/fried/qt_fried_msg.py#OpenComment` 等
///
/// 第九批升级：除评论列表外，详情页顶部追加 post 自身（用户信息 / 文本 / 配图 / 点赞），
/// 与列表页保持一致；并新增「动态点赞」按钮对齐「评论点赞」交互。
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

  /// 动态点赞（先发请求，成功/失败后 invalidate 触发重新拉取）
  ///
  /// 第九批新增：调用 PUT `/posts/{id}/like`，完成后 invalidate
  /// `friendPostProvider` + `friendPostsProvider` 拉取最新真实值。
  /// 失败用 SnackBar 提示。
  ///
  /// 故意不做"乐观更新"——服务端确认后再 refresh 更可靠，避免与
  /// 服务端状态不一致。性能上锅贴点赞是低频操作，可接受。
  Future<void> _togglePostLike(FriendPost post) async {
    final repo = ref.read(friendRepositoryProvider);
    try {
      await repo.likePost(post.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('点赞失败: $e')),
      );
      return;
    }
    // 成功后重新拉取最新数据（detail header + 列表 item）
    ref.invalidate(friendPostProvider(post.id));
    ref.invalidate(friendPostsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final asyncPost = ref.watch(friendPostProvider(widget.postId));
    final post = asyncPost.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('动态详情'),
        actions: [
          IconButton(
            tooltip: '刷新',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(friendPostProvider(widget.postId));
              _load();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(friendPostProvider(widget.postId));
                await _load();
              },
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.all(12),
                children: [
                  if (post != null)
                    _PostHeader(
                      post: post,
                      onLike: () => _togglePostLike(post),
                    )
                  else if (asyncPost.isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (asyncPost.hasError)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          '动态加载失败: ${asyncPost.error}',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),

                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      '评论 (${_comments.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),

                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null)
                    _ErrorState(message: _error!, onRetry: _load)
                  else if (_comments.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          '还没有评论',
                          style: TextStyle(color: AppColors.secondaryText),
                        ),
                      ),
                    )
                  else
                    ..._comments.map(
                      (c) => _CommentTile(
                        comment: c,
                        onLike: () => _like(c),
                      ),
                    ),
                ],
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

/// Post 自身（用户信息 + 文本 + 配图 + 点赞）
///
/// 第九批新增：详情页头部卡片，与列表页 item 视觉一致，
/// 但宽度更大可展示完整文本 + 全部配图缩略。
class _PostHeader extends StatelessWidget {
  final FriendPost post;
  final VoidCallback onLike;
  const _PostHeader({required this.post, required this.onLike});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ========== 用户信息 ==========
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.darkCard,
                backgroundImage: post.user.avatar.isNotEmpty
                    ? CachedNetworkImageProvider(post.user.avatar)
                    : null,
                child: post.user.avatar.isEmpty
                    ? const Icon(Icons.person, color: Colors.white54)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            post.user.name.isEmpty ? '匿名' : post.user.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (post.user.title.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              post.user.title,
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      'LV${post.user.level} · ${_formatDateTime(post.createdAt)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ========== 文本内容（详情页不截断） ==========
          Text(
            post.content.isEmpty ? '(无文本内容)' : post.content,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 8),

          // ========== 配图（最多显示 3 张，剩余显示 +N） ==========
          if (post.medias.isNotEmpty) _MediaGrid(medias: post.medias),

          const SizedBox(height: 8),

          // ========== 互动数据 + 动态点赞 ==========
          Row(
            children: [
              InkWell(
                onTap: onLike,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        post.liked ? Icons.favorite : Icons.favorite_border,
                        size: 18,
                        color: post.liked ? Colors.pink : null,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${post.totalLikes}',
                        style: TextStyle(
                          color: post.liked ? Colors.pink : null,
                          fontWeight:
                              post.liked ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.comment_outlined,
                size: 16,
                color: AppColors.secondaryText,
              ),
              const SizedBox(width: 4),
              Text(
                '${post.totalComments}',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                'ID: ${post.id}',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatDateTime(DateTime? d) {
    if (d == null) return '';
    return DateFormat('yyyy-MM-dd HH:mm').format(d.toLocal());
  }
}

/// 配图网格（最多 3 张，剩余显示 +N 角标）
class _MediaGrid extends StatelessWidget {
  final List<String> medias;
  const _MediaGrid({required this.medias});

  @override
  Widget build(BuildContext context) {
    if (medias.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedImage(
          imageUrl: medias.first,
          fit: BoxFit.cover,
          height: 200,
          width: double.infinity,
        ),
      );
    }
    final shown = medias.take(3).toList();
    final extra = medias.length - shown.length;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: shown.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemBuilder: (context, i) {
        final url = shown[i];
        final isLast = i == shown.length - 1 && extra > 0;
        return Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CachedImage(
                imageUrl: url,
                fit: BoxFit.cover,
              ),
            ),
            if (isLast)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '+$extra',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
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
