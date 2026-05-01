import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../shared/constants/api_constants.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/widgets/comic_card.dart';
import '../domain/comic_model.dart';
import 'comic_detail_screen.dart';

/// 漫画列表 Provider
final comicListProvider = FutureProvider<List<Comic>>((ref) async {
  final api = ApiClient.instance;
  final response = await api.get(ApiEndpoints.comics, queryParameters: {
    's': 'dd',
    'page': 1,
  });
  final data = response.data['data'];
  final comics = (data['comics'] as List)
      .map((json) => Comic.fromJson(json))
      .toList();
  return comics;
});

/// 漫画列表页
class ComicListScreen extends ConsumerWidget {
  const ComicListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncComics = ref.watch(comicListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('哔咔漫画'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // TODO: 跳转阅读历史
            },
          ),
        ],
      ),
      body: asyncComics.when(
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
                onPressed: () => ref.invalidate(comicListProvider),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
        data: (comics) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(comicListProvider);
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
        ),
      ),
    );
  }
}
