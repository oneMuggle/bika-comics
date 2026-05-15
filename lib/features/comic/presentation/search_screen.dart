import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/db/database.dart' hide Comic;
import '../../../shared/constants/api_constants.dart';
import '../../../shared/constants/app_colors.dart';
import '../domain/comic_model.dart';
import 'categories_screen.dart';
import 'comic_detail_screen.dart';

/// 搜索 Provider
final searchQueryProvider = StateProvider<String>((ref) => '');
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

final searchResultProvider = FutureProvider<List<Comic>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  final category = ref.watch(selectedCategoryProvider);
  if (query.isEmpty) return [];

  final api = ApiClient.instance;
  final response = await api.get(ApiEndpoints.search(q: query, categories: category));
  final data = response.data['data'];
  final comics = (data['comics'] as List)
      .map((json) => Comic.fromJson(json))
      .toList();
  return comics;
});

/// 搜索页
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _search(String query) async {
    if (query.trim().isEmpty) return;
    final q = query.trim();
    // 保存搜索历史
    try {
      DatabaseHolder.instance.insertSearchHistory(q);
    } catch (_) {}
    ref.read(searchQueryProvider.notifier).state = q;
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(searchResultProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final asyncCategories = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: '搜索漫画...',
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _controller.clear();
                ref.read(searchQueryProvider.notifier).state = '';
              },
            ),
          ),
          onSubmitted: _search,
          textInputAction: TextInputAction.search,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _search(_controller.text),
          ),
        ],
      ),
      body: Column(
        children: [
          // Category filter chips
          asyncCategories.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (categories) => SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: categories.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    final isSelected = selectedCategory == null;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('全部'),
                        selected: isSelected,
                        onSelected: (_) {
                          ref.read(selectedCategoryProvider.notifier).state = null;
                          if (ref.read(searchQueryProvider).isNotEmpty) {
                            ref.invalidate(searchResultProvider);
                          }
                        },
                      ),
                    );
                  }
                  final category = categories[index - 1];
                  final isSelected = selectedCategory == category.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(category.title),
                      selected: isSelected,
                      onSelected: (_) {
                        ref.read(selectedCategoryProvider.notifier).state = category.id;
                        if (ref.read(searchQueryProvider).isNotEmpty) {
                          ref.invalidate(searchResultProvider);
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ),
          if (selectedCategory != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  const Text('筛选: ', style: TextStyle(fontSize: 12)),
                  Chip(
                    label: Text(
                      asyncCategories.valueOrNull
                              ?.firstWhere((c) => c.id == selectedCategory, orElse: () => asyncCategories.value!.first)
                              .title ?? selectedCategory,
                      style: const TextStyle(fontSize: 12),
                    ),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () {
                      ref.read(selectedCategoryProvider.notifier).state = null;
                      if (ref.read(searchQueryProvider).isNotEmpty) {
                        ref.invalidate(searchResultProvider);
                      }
                    },
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          Expanded(
            child: results.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('搜索失败: $e')),
              data: (comics) {
                if (comics.isEmpty && ref.watch(searchQueryProvider).isNotEmpty) {
                  return const Center(child: Text('没有找到相关漫画'));
                }
                return GridView.builder(
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
                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                ComicDetailScreen(comicId: comic.id),
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                comic.coverUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: AppColors.darkCard,
                                  child: const Icon(Icons.broken_image),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            comic.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
