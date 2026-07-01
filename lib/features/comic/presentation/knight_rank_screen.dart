import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/constants/app_colors.dart';
import '../../../shared/widgets/cached_image.dart';
import '../domain/knight_model.dart';
import '../data/knight_repository.dart';

/// 骑士榜页面（排行榜的第 4 个 Tab）
///
/// 桌面端: view/category/rank_view.py 的第 3 个 Tab (index=3)
/// 桌面端 API: GET /comics/knight-leaderboard
class KnightRankScreen extends ConsumerWidget {
  const KnightRankScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncUsers = ref.watch(knightRankProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(knightRankProvider);
      },
      child: asyncUsers.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => ListView(
          // ListView 让 RefreshIndicator 在错误态仍可下拉
          children: [
            const SizedBox(height: 80),
            Center(
              child: Column(
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text('加载失败: $e',
                      style: const TextStyle(color: AppColors.secondaryText)),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => ref.invalidate(knightRankProvider),
                    child: const Text('重试'),
                  ),
                ],
              ),
            ),
          ],
        ),
        data: (users) {
          if (users.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 120),
                Center(child: Text('暂无数据')),
              ],
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: users.length,
            itemBuilder: (context, index) =>
                _KnightCard(rank: index + 1, user: users[index]),
          );
        },
      ),
    );
  }
}

class _KnightCard extends StatelessWidget {
  final int rank;
  final KnightUser user;

  const _KnightCard({required this.rank, required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // 排名
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getRankColor(rank),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 头像
            ClipOval(
              child: SizedBox(
                width: 56,
                height: 56,
                child: user.hasAvatar
                    ? CachedImage(
                        imageUrl: user.avatar.url,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      )
                    : _placeholderAvatar(),
              ),
            ),
            const SizedBox(width: 12),
            // 用户信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.name.isEmpty ? '匿名骑士' : user.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (user.title.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            user.title,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (user.slogan.isNotEmpty)
                    Text(
                      user.slogan,
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.military_tech,
                          size: 14, color: AppColors.secondaryText),
                      const SizedBox(width: 4),
                      Text(
                        'Lv.${user.level}',
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
          ],
        ),
      ),
    );
  }

  Widget _placeholderAvatar() => Container(
        color: AppColors.darkCard,
        child: const Icon(Icons.person, color: Colors.white54),
      );

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber.shade600;
      case 2:
        return Colors.grey.shade400;
      case 3:
        return Colors.brown.shade300;
      default:
        return AppColors.primary.withValues(alpha: 0.7);
    }
  }
}
