import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../shared/constants/api_constants.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/widgets/comic_card.dart';
import '../domain/comic_model.dart';
import 'comic_detail_screen.dart';

/// 排行榜类型
enum RankType {
  daily('日榜', 'd'),
  weekly('周榜', 'w'),
  monthly('月榜', 'm');

  final String label;
  final String value;
  const RankType(this.label, this.value);
}

/// 排行榜 Provider
final rankTypeProvider = StateProvider<RankType>((ref) => RankType.daily);

final leaderboardProvider = FutureProvider<List<Comic>>((ref) async {
  final rankType = ref.watch(rankTypeProvider);
  final api = ApiClient.instance;
  final response = await api.get(
    ApiEndpoints.comicsRank,
    queryParameters: {'tt': rankType.value, 'ct': 'VC'},
  );
  final data = response.data['data'];
  final comics = (data['comics'] as List)
      .map((json) => Comic.fromJson(json))
      .toList();
  return comics;
});

/// 排行榜页面
class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncLeaderboard = ref.watch(leaderboardProvider);
    final currentRankType = ref.watch(rankTypeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('排行榜'),
        actions: [
          PopupMenuButton<RankType>(
            icon: const Icon(Icons.filter_list),
            onSelected: (type) {
              ref.read(rankTypeProvider.notifier).state = type;
            },
            itemBuilder: (context) => RankType.values
                .map((type) => PopupMenuItem(
                      value: type,
                      child: Row(
                        children: [
                          if (type == currentRankType)
                            const Icon(Icons.check, size: 18)
                          else
                            const SizedBox(width: 18),
                          const SizedBox(width: 8),
                          Text(type.label),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
      body: asyncLeaderboard.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('加载失败: $error'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(leaderboardProvider),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
        data: (comics) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(leaderboardProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: comics.length,
            itemBuilder: (context, index) {
              final comic = comics[index];
              return _RankCard(
                rank: index + 1,
                comic: comic,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ComicDetailScreen(comicId: comic.id),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RankCard extends StatelessWidget {
  final int rank;
  final Comic comic;
  final VoidCallback onTap;

  const _RankCard({
    required this.rank,
    required this.comic,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
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
              // 封面
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  comic.coverUrl,
                  width: 60,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 60,
                    height: 80,
                    color: AppColors.darkCard,
                    child: const Icon(Icons.broken_image),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comic.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      comic.author,
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.visibility, size: 14, color: AppColors.secondaryText),
                        const SizedBox(width: 4),
                        Text(
                          '${comic.totalViews}',
                          style: TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.favorite, size: 14, color: AppColors.error),
                        const SizedBox(width: 4),
                        Text(
                          '${comic.likeCount}',
                          style: TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey.shade400;
      case 3:
        return Colors.brown.shade300;
      default:
        return AppColors.primary;
    }
  }
}
