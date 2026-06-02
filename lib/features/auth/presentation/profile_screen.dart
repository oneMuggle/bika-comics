import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/constants/app_colors.dart';
import '../data/auth_repository.dart';
import '../data/user_repository.dart';
import '../domain/auth_state.dart';
import '../../comic/domain/comment_model.dart';

/// 我的评论 Provider (GET /users/my-comments)
final myCommentsProvider =
    FutureProvider.family<List<Comment>, int>((ref, page) async {
  final repo = ref.read(userRepositoryProvider);
  return await repo.getMyComments(page: page);
});

/// 个人中心页
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _punching = false;

  @override
  void initState() {
    super.initState();
    // 进入页面时尝试刷新用户资料
    Future.microtask(() {
      if (mounted) {
        ref.read(authStateProvider.notifier).refreshProfile();
      }
    });
  }

  Future<void> _doPunchIn() async {
    if (_punching) return;
    setState(() => _punching = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final msg = await ref.read(authStateProvider.notifier).punchIn();
      messenger.showSnackBar(
        SnackBar(
          content: Text('签到成功：$msg'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('签到失败：$e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _punching = false);
      }
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('退出'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authStateProvider.notifier).logout();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);

    if (!auth.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('个人中心')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('尚未登录'),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamed('/login');
                },
                icon: const Icon(Icons.login),
                label: const Text('去登录'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('个人中心'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _confirmLogout,
            tooltip: '退出登录',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(authStateProvider.notifier).refreshProfile();
          ref.invalidate(myCommentsProvider(1));
        },
        child: ListView(
          children: [
            _buildUserHeader(auth.user),
            const SizedBox(height: 8),
            _buildActionGrid(),
            const Divider(height: 32),
            _buildSectionTitle('我的评论'),
            _buildMyComments(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader(AuthUser? user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: Colors.white24,
            backgroundImage:
                (user?.avatar.isNotEmpty ?? false)
                    ? CachedNetworkImageProvider(user!.avatar)
                    : null,
            child: (user?.avatar.isEmpty ?? true)
                ? const Icon(Icons.person, size: 40, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.name.isNotEmpty == true ? user!.name : '未命名用户',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                if (user != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Lv.${user.level}',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: _ActionTile(
              icon: Icons.check_circle_outline,
              label: '每日签到',
              onTap: _doPunchIn,
              loading: _punching,
            ),
          ),
          Expanded(
            child: _ActionTile(
              icon: Icons.history,
              label: '阅读历史',
              onTap: () => Navigator.pushNamed(context, '/history'),
            ),
          ),
          Expanded(
            child: _ActionTile(
              icon: Icons.favorite,
              label: '我的收藏',
              onTap: () => Navigator.pushNamed(context, '/favourites'),
            ),
          ),
          Expanded(
            child: _ActionTile(
              icon: Icons.bookmark,
              label: '我的追漫',
              onTap: () => Navigator.pushNamed(context, '/follows'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.subject, color: AppColors.primary, size: 18),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildMyComments() {
    final async = ref.watch(myCommentsProvider(1));
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text('加载评论失败：$e',
            style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ),
      data: (comments) {
        if (comments.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Text('还没有发过评论',
                style: TextStyle(color: Colors.grey)),
          );
        }
        return Column(
          children: comments.take(20).map((c) => _CommentTile(c: c)).toList(),
        );
      },
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool loading;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: loading ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        child: Column(
          children: [
            loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(icon, size: 28, color: AppColors.primary),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final Comment c;
  const _CommentTile({required this.c});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withAlpha(40),
        backgroundImage: c.userAvatar.isNotEmpty
            ? CachedNetworkImageProvider(c.userAvatar)
            : null,
        child: c.userAvatar.isEmpty
            ? Text(
                c.userName.isNotEmpty ? c.userName[0] : '?',
                style: TextStyle(color: AppColors.primary),
              )
            : null,
      ),
      title: Text(c.userName, style: const TextStyle(fontSize: 13)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(
            c.content,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Text(
                c.createdAt,
                style: const TextStyle(color: Colors.grey, fontSize: 10),
              ),
              const Spacer(),
              const Icon(Icons.thumb_up, size: 10, color: Colors.grey),
              const SizedBox(width: 2),
              Text(
                '${c.likeCount}',
                style: const TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: null,
    );
  }
}
