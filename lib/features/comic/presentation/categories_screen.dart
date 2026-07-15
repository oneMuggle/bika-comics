import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../shared/constants/api_constants.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/widgets/comic_card.dart';
import '../data/forbid_words_filter_helper.dart';
import '../domain/comic_model.dart';
import 'comic_detail_screen.dart';

/// 分类模型
class Category {
  final String id;
  final String title;
  final String cover;

  const Category({
    required this.id,
    required this.title,
    required this.cover,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      cover: json['cover'] is String
          ? json['cover']
          : (json['cover']?['path'] ?? ''),
    );
  }
}

/// 分类列表 Provider
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final api = ApiClient.instance;
  final response = await api.get(ApiEndpoints.categories);
  final data = response.data['data'];
  final categories = (data['categories'] as List)
      .map((json) => Category.fromJson(json))
      .toList();
  return categories;
});

/// 分类漫画 Provider（按分类对象 family）
/// 第二十四批追加修复：旧实现使用 `ApiEndpoints.categoryComics?ccat=<id>`
/// 但桌面端 CategoriesSearchReq 实际使用 `comics?page=&c=&s=`（c 为分类标题）。
/// 因此传入整个 Category 对象以便在 provider 内构造端点。
final categoryComicsProvider =
    FutureProvider.family<List<Comic>, Category>((ref, category) async {
  final api = ApiClient.instance;
  // 使用 ApiEndpoints.categoryComics 纯函数构造 URL（可独立单测）
  final url = ApiEndpoints.categoryComics(category: category.title);
  final response = await api.get(url);
  final data = response.data['data'];
  final comics =
      (data['comics'] as List).map((json) => Comic.fromJson(json)).toList();
  return comics;
});

/// 分类浏览页
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCategories = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('分类'),
      ),
      body: asyncCategories.when(
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
                onPressed: () => ref.invalidate(categoriesProvider),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
        data: (categories) => GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return _CategoryCard(
              category: category,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        CategoryComicsScreen(category: category),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final Category category;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withAlpha(200),
              AppColors.primaryDark.withAlpha(200),
            ],
          ),
        ),
        child: Center(
          child: Text(
            category.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

/// 分类漫画列表页
class CategoryComicsScreen extends ConsumerWidget {
  final Category category;

  const CategoryComicsScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncComics = ref.watch(categoryComicsProvider(category));
    final displayList = ref.watch(
      filteredComicsProvider(asyncComics.valueOrNull ?? const <Comic>[]),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(category.title),
      ),
      body: asyncComics.when(
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
                onPressed: () =>
                    ref.invalidate(categoryComicsProvider(category)),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
        data: (comics) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(categoryComicsProvider(category));
          },
          child: displayList.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child:
                        Text('没有可显示的漫画', style: TextStyle(color: Colors.grey)),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: displayList.length,
                  itemBuilder: (context, index) {
                    final comic = displayList[index];
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
        ),
      ),
    );
  }
}
