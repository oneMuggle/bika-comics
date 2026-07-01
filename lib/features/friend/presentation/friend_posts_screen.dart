import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/constants/app_colors.dart';
import '../../../shared/widgets/cached_image.dart';
import '../data/friend_repository.dart';
import '../domain/friend_post_model.dart';
import 'friend_post_detail_screen.dart';

/// 好友动态列表（锅贴）
///
/// 对应桌面端 `view/fried/fried_view.py`
/// - 桌面端使用 QListWidget + spinBox 翻页
/// - 移动端使用 ListView + 上拉加载更多（基于 offset）
class FriendPostsScreen extends ConsumerStatefulWidget {
  const FriendPostsScreen({super.key});

  @override
  ConsumerState<FriendPostsScreen> createState() => _FriendPostsScreenState();
}

class _FriendPostsScreenState extends ConsumerState<FriendPostsScreen> {
  final ScrollController _scroll = ScrollController();
  int _offset = 0;
  bool _loadingMore = false;
  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels >=
        _scroll.position.maxScrollExtent - 240) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore) return;
    final current = ref.read(friendPostsProvider(_offset));
    final value = current.valueOrNull;
    if (value == null) return;
    if (_offset + _pageSize >= value.total && value.posts.isNotEmpty) return;
    setState(() => _loadingMore = true);
    setState(() => _offset += _pageSize);
    setState(() => _loadingMore = false);
  }

  Future<void> _onRefresh() async {
    setState(() => _offset = 0);
    ref.invalidate(friendPostsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(friendPostsProvider(0));

    return Scaffold(
      appBar: AppBar(
        title: const Text('好友动态'),
        actions: [
          IconButton(
            tooltip: '刷新',
            icon: const Icon(Icons.refresh),
            onPressed: _onRefresh,
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(
          message: '$e',
          onRetry: _onRefresh,
        ),
        data: (first) {
          final allPosts = <FriendPost>[...first.posts];
          for (int o = _pageSize; o <= _offset; o += _pageSize) {
            final page = ref.watch(friendPostsProvider(o)).valueOrNull;
            if (page != null) allPosts.addAll(page.posts);
          }
          if (allPosts.isEmpty) {
            return const _EmptyState();
          }
          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(12),
              itemCount: allPosts.length + 1,
              itemBuilder: (context, i) {
                if (i == allPosts.length) {
                  if (_loadingMore) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  if (allPosts.length < first.total) {
                    return Center(
                      child: TextButton(
                        onPressed: _loadMore,
                        child: const Text('加载更多'),
                      ),
                    );
                  }
                  return const SizedBox(height: 24);
                }
                return _FriendPostCard(post: allPosts[i]);
              },
            ),
          );
        },
      ),
    );
  }
}

class _FriendPostCard extends StatelessWidget {
  final FriendPost post;
  const _FriendPostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FriendPostDetailScreen(postId: post.id),
            ),
          );
        },
        child: Padding(
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
                                post.user.name,
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
                                  color: AppColors.primary
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  post.user.title,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          'LV${post.user.level} · ${_formatDate(post.createdAt)}',
                          style: const TextStyle(
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

              // ========== 内容 ==========
              Text(
                post.content,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // ========== 配图（仅显示第一张） ==========
              if (post.medias.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedImage(
                    imageUrl: post.medias.first,
                    fit: BoxFit.cover,
                    height: 200,
                    width: double.infinity,
                  ),
                ),

              const SizedBox(height: 8),

              // ========== 互动数据 ==========
              Row(
                children: [
                  Icon(Icons.favorite, size: 16, color: Colors.pink.shade300),
                  const SizedBox(width: 4),
                  Text(
                    '${post.totalLikes}',
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.comment, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${post.totalComments}',
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime? d) {
    if (d == null) return '';
    return DateFormat('yyyy-MM-dd HH:mm').format(d.toLocal());
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.forum_outlined,
              size: 56, color: AppColors.secondaryText),
          SizedBox(height: 12),
          Text(
            '暂无动态',
            style: TextStyle(color: AppColors.secondaryText),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              '提示：锅贴由独立服务器 post-api.wikawika.xyz 提供，需要保持登录状态',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
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
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              '加载失败: $message',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.secondaryText),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}
