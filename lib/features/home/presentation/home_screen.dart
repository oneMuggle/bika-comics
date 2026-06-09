import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../shared/constants/api_constants.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/widgets/comic_card.dart';
import '../../comic/data/forbid_words_filter_helper.dart';
import '../../comic/domain/comic_model.dart';
import '../../comic/presentation/comic_detail_screen.dart';

/// 首页 collections 数据模型
class ComicCollection {
  final String title;
  final List<Comic> comics;

  const ComicCollection({required this.title, required this.comics});
}

/// 首页推荐 Provider
final homeCollectionsProvider =
    FutureProvider<List<ComicCollection>>((ref) async {
  final api = ApiClient.instance;
  final response = await api.get('/collections');
  final data = response.data['data'];

  final collections = <ComicCollection>[];
  final rawCollections = data['collections'] as List? ?? [];
  for (final cat in rawCollections) {
    final title = cat['title'] as String? ?? '';
    final comicsList = (cat['comics'] as List? ?? [])
        .map((c) => Comic.fromJson(c as Map<String, dynamic>))
        .toList();
    collections.add(ComicCollection(title: title, comics: comicsList));
  }
  return collections;
});

/// 首页随机 Provider
final homeRandomProvider = FutureProvider<List<Comic>>((ref) async {
  final api = ApiClient.instance;
  final response = await api.get(ApiEndpoints.comicsRandom);
  final data = response.data['data'];
  final comics = (data['comics'] as List? ?? [])
      .map((c) => Comic.fromJson(c as Map<String, dynamic>))
      .toList();
  return comics;
});

/// 首页 Tab State
final homeTabIndexProvider = StateProvider<int>((ref) => 0);

/// 首页屏幕
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabIndex = ref.watch(homeTabIndexProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('哔咔漫画'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.pushNamed(context, '/history');
            },
          ),
        ],
        bottom: TabBar(
          onTap: (index) {
            ref.read(homeTabIndexProvider.notifier).state = index;
          },
          tabs: const [
            Tab(text: '推荐'),
            Tab(text: '随机'),
          ],
        ),
      ),
      body: TabBarView(
        children: const [
          _CollectionsTab(),
          _RandomTab(),
        ],
      ),
    );
  }
}

/// 推荐 Tab
class _CollectionsTab extends ConsumerWidget {
  const _CollectionsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCollections = ref.watch(homeCollectionsProvider);

    return asyncCollections.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text('加载失败: $e'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.invalidate(homeCollectionsProvider),
              child: const Text('重试'),
            ),
          ],
        ),
      ),
      data: (collections) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(homeCollectionsProvider);
        },
        child: collections.isEmpty
            ? const Center(child: Text('暂无推荐内容'))
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: collections.length,
                itemBuilder: (context, index) {
                  final collection = collections[index];
                  return _CollectionSection(collection: collection);
                },
              ),
      ),
    );
  }
}

/// 随机 Tab
class _RandomTab extends ConsumerWidget {
  const _RandomTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRandom = ref.watch(homeRandomProvider);

    return asyncRandom.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text('加载失败: $e'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.invalidate(homeRandomProvider),
              child: const Text('重试'),
            ),
          ],
        ),
      ),
      data: (comics) {
        final filtered = ref.watch(filteredComicsProvider(comics));
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(homeRandomProvider);
          },
          child: filtered.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('没有可显示的漫画',
                        style: TextStyle(color: Colors.grey)),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final comic = filtered[index];
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
    );
  }
}

/// 推荐区块 Section
class _CollectionSection extends ConsumerWidget {
  final ComicCollection collection;

  const _CollectionSection({required this.collection});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtered =
        ref.watch(filteredComicsProvider(collection.comics));
    if (filtered.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            collection.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final comic = filtered[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: SizedBox(
                  width: 130,
                  child: ComicCard(
                    id: comic.id,
                    title: comic.title,
                    coverUrl: comic.coverUrl,
                    subtitle: '${comic.episodeCount}话',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              ComicDetailScreen(comicId: comic.id),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
