import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/constants/app_colors.dart';
import '../../../shared/widgets/cached_image.dart';
import '../data/game_repository.dart';
import '../domain/game_model.dart';
import 'game_detail_screen.dart';

/// 游戏区列表页面
///
/// 对应桌面端: src/view/game/game_view.py
/// - 桌面端使用 QListWidget 翻页（spinBox + LoadNextPage）
/// - 移动端使用无限滚动的 GridView，触底加载下一页
class GameListScreen extends ConsumerStatefulWidget {
  const GameListScreen({super.key});

  @override
  ConsumerState<GameListScreen> createState() => _GameListScreenState();
}

class _GameListScreenState extends ConsumerState<GameListScreen> {
  final ScrollController _scroll = ScrollController();
  int _page = 1;
  bool _loadingMore = false;

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
    final current = ref.read(gamesListProvider(_page));
    final value = current.valueOrNull;
    if (value == null) return;
    if (value.page >= value.pages) return;
    setState(() => _loadingMore = true);
    setState(() => _page += 1);
    setState(() => _loadingMore = false);
  }

  Future<void> _onRefresh() async {
    setState(() => _page = 1);
    ref.invalidate(gamesListProvider);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(gamesListProvider(1));

    return Scaffold(
      appBar: AppBar(
        title: const Text('游戏区'),
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
          // 合并多页结果：把 _page 之后所有已加载页拼接
          final allGames = <Game>[...first.games];
          for (int p = 2; p <= _page; p++) {
            final pageData = ref.watch(gamesListProvider(p)).valueOrNull;
            if (pageData != null) allGames.addAll(pageData.games);
          }
          if (allGames.isEmpty) {
            return const _EmptyState();
          }
          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: GridView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(12),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.62,
              ),
              itemCount: allGames.length + 1,
              itemBuilder: (context, index) {
                if (index == allGames.length) {
                  if (_loadingMore) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  if (first.page < first.pages) {
                    return Center(
                      child: TextButton(
                        onPressed: _loadMore,
                        child: const Text('加载更多'),
                      ),
                    );
                  }
                  return const SizedBox(height: 24);
                }
                final g = allGames[index];
                return _GameCard(game: g);
              },
            ),
          );
        },
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final Game game;
  const _GameCard({required this.game});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GameDetailScreen(gameId: game.id),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedImage(
                    imageUrl: game.icon.url,
                    fit: BoxFit.cover,
                  ),
                  if (game.adult)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'R18',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (game.suggest)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '推荐',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            game.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (game.publisher.isNotEmpty)
            Text(
              game.publisher,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.secondaryText,
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.videogame_asset_off,
              size: 56, color: AppColors.secondaryText),
          const SizedBox(height: 12),
          Text(
            '暂无游戏',
            style: TextStyle(color: AppColors.secondaryText),
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
