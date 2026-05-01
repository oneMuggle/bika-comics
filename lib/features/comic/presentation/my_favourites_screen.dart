import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../shared/constants/api_constants.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/widgets/comic_card.dart';
import '../data/comic_repository.dart';
import '../domain/comic_model.dart';
import 'comic_detail_screen.dart';

/// 我的收藏 Provider
final myFavouritesProvider = FutureProvider<List<Comic>>((ref) async {
  final repo = ref.read(comicRepositoryProvider);
  return repo.getMyFavourites();
});

/// 我的收藏页
class MyFavouritesScreen extends ConsumerWidget {
  const MyFavouritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncFavourites = ref.watch(myFavouritesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的收藏'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(myFavouritesProvider),
          ),
        ],
      ),
      body: asyncFavourites.when(
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
                onPressed: () => ref.invalidate(myFavouritesProvider),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
        data: (comics) {
          if (comics.isEmpty) {
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
              ref.invalidate(myFavouritesProvider);
            },
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.65,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: comics.length,
              itemBuilder: (context, index) {
                final comic = comics[index];
                return ComicCard(
                  id: comic.id,
                  title: comic.title,
                  coverUrl: comic.coverUrl,
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
          );
        },
      ),
    );
  }
}
