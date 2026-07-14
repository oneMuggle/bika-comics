import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/constants/app_colors.dart';
import '../../../shared/widgets/comic_card.dart';
import '../data/comic_repository.dart';
import '../data/forbid_words_filter_helper.dart';
import '../domain/comic_model.dart';
import 'comic_detail_screen.dart';

/// 第二十四批：我的收藏排序选项
///
/// 桌面端 favorite_view.py `self.sortList = ["dd", "da"]`：
/// - `dd` = 新到旧（date desc）
/// - `da` = 旧到新（date asc）
enum FavouritesSort {
  /// 新到旧（date desc，桌面下拉框第一项）
  newestFirst('dd', '新到旧'),

  /// 旧到新（date asc）
  oldestFirst('da', '旧到新');

  final String apiValue;
  final String label;

  const FavouritesSort(this.apiValue, this.label);
}

/// 我的收藏排序状态（StateProvider，UI 可写）
final favouritesSortProvider = StateProvider<FavouritesSort>((ref) {
  return FavouritesSort.newestFirst;
});

/// 我的收藏 Provider（按排序 key family）
/// 切换排序时 family key 变化 → 重新拉取；手动 invalidate 也会触发刷新。
final myFavouritesProvider =
    FutureProvider.family<List<Comic>, FavouritesSort>((ref, sort) async {
  final repo = ref.read(comicRepositoryProvider);
  return repo.getMyFavourites(sort: sort.apiValue);
});

/// 我的收藏页
class MyFavouritesScreen extends ConsumerWidget {
  const MyFavouritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sort = ref.watch(favouritesSortProvider);
    final asyncFavourites = ref.watch(myFavouritesProvider(sort));
    // 屏蔽词过滤（设置中开关后会自动重算）
    final filteredFavourites = ref.watch(
      filteredComicsProvider(asyncFavourites.valueOrNull ?? const <Comic>[]),
    );
    final displayList = filteredFavourites;

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的收藏'),
        actions: [
          // 第二十四批：排序选择（dd / da）
          PopupMenuButton<FavouritesSort>(
            tooltip: '排序',
            icon: const Icon(Icons.sort),
            initialValue: sort,
            onSelected: (value) {
              ref.read(favouritesSortProvider.notifier).state = value;
              // family key 变化会自动重新拉取；显式 invalidate 让 UI 立即进入 loading。
              ref.invalidate(myFavouritesProvider(value));
            },
            itemBuilder: (context) => [
              for (final option in FavouritesSort.values)
                CheckedPopupMenuItem<FavouritesSort>(
                  value: option,
                  checked: option == sort,
                  child: Text(option.label),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(myFavouritesProvider(sort)),
          ),
        ],
      ),
      body: asyncFavourites.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('加载失败: $error'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(myFavouritesProvider(sort)),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
        data: (comics) {
          final list = displayList;
          if (list.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('暂无收藏', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(myFavouritesProvider(sort));
            },
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.65,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final comic = list[index];
                return ComicCard(
                  id: comic.id,
                  title: comic.title,
                  coverUrl: comic.coverUrl,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            ComicDetailScreen(comicId: comic.id),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
