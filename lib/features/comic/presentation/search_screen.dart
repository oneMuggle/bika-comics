import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/db/database.dart' hide Comic;
import '../../../shared/constants/api_constants.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_strings.dart';
import '../data/comic_repository.dart';
import '../data/forbid_words_filter_helper.dart';
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

/// 搜索热词 Provider (GET /keywords)
final searchKeywordsProvider = FutureProvider<List<String>>((ref) async {
  final repo = ref.read(comicRepositoryProvider);
  try {
    return await repo.getKeywords();
  } catch (_) {
    return const [];
  }
});

/// 本地搜索历史 Provider (Drift)
final localSearchHistoryProvider = FutureProvider<List<String>>((ref) async {
  try {
    final rows = await DatabaseHolder.instance.getSearchHistory(limit: 10);
    return rows.map((r) => r.keyword).toList();
  } catch (_) {
    return const [];
  }
});

/// 搜索页
class SearchScreen extends ConsumerStatefulWidget {
  /// 第十五批：初始搜索关键词 — 详情页点击 tag 时传入
  final String initialKeyword;

  const SearchScreen({super.key, this.initialKeyword = ''});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _didApplyInitial = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialKeyword.isNotEmpty) {
      _controller.text = widget.initialKeyword;
      // 首次 build 后自动触发搜索（等 provider 就绪）
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_didApplyInitial) {
          _didApplyInitial = true;
          _search(widget.initialKeyword);
        }
      });
    }
  }

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
    // 刷新历史列表
    ref.invalidate(localSearchHistoryProvider);
  }

  Future<void> _clearHistory() async {
    try {
      await DatabaseHolder.instance.clearSearchHistory();
      ref.invalidate(localSearchHistoryProvider);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(searchResultProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final asyncCategories = ref.watch(categoriesProvider);
    final hasQuery = ref.watch(searchQueryProvider).isNotEmpty;
    final asyncKeywords = ref.watch(searchKeywordsProvider);
    final asyncHistory = ref.watch(localSearchHistoryProvider);
    // 屏蔽词过滤（与历史 / 热词 chip 区无关，仅作用于搜索结果列表）
    final filteredResults =
        ref.watch(filteredComicsProvider(results.valueOrNull ?? const <Comic>[]));

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
            icon: const Icon(Icons.filter_list),
            tooltip: '高级搜索',
            onPressed: () {
              Navigator.of(context).pushNamed('/advanced-search');
            },
          ),
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
            child: !hasQuery
                ? _buildDiscover(
                    context,
                    asyncKeywords,
                    asyncHistory,
                  )
                : results.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, s) => Center(child: Text('搜索失败: $e')),
                    data: (comics) {
                      if (filteredResults.isEmpty &&
                          ref.watch(searchQueryProvider).isNotEmpty) {
                        return const Center(child: Text('没有找到相关漫画'));
                      }
                      return GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: filteredResults.length,
                        itemBuilder: (context, index) {
                          final comic = filteredResults[index];
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

  Widget _buildDiscover(
    BuildContext context,
    AsyncValue<List<String>> asyncKeywords,
    AsyncValue<List<String>> asyncHistory,
  ) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // 搜索热词
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.local_fire_department,
                  size: 18, color: Colors.orange),
              SizedBox(width: 6),
              Text(
                '热门搜索',
                style:
                    TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        asyncKeywords.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (_, __) => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('获取热词失败',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
          data: (keywords) {
            if (keywords.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('暂无热词',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
              );
            }
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: keywords
                    .map(
                      (kw) => ActionChip(
                        avatar: const Icon(
                          Icons.trending_up,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        label: Text(kw),
                        onPressed: () {
                          _controller.text = kw;
                          _controller.selection = TextSelection.collapsed(
                              offset: kw.length);
                          _search(kw);
                        },
                      ),
                    )
                    .toList(),
              ),
            );
          },
        ),

        const SizedBox(height: 16),

        // 搜索历史
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.history, size: 18, color: Colors.blueGrey),
              const SizedBox(width: 6),
              const Text(
                AppStrings.searchHistory,
                style:
                    TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              asyncHistory.maybeWhen(
                data: (list) => list.isEmpty
                    ? const SizedBox.shrink()
                    : TextButton.icon(
                        onPressed: _clearHistory,
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text(AppStrings.clearHistory,
                            style: TextStyle(fontSize: 12)),
                      ),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        asyncHistory.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (_, __) => const SizedBox.shrink(),
          data: (history) {
            if (history.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('暂无搜索历史',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
              );
            }
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: history
                    .map(
                      (kw) => InputChip(
                        label: Text(kw),
                        onPressed: () {
                          _controller.text = kw;
                          _controller.selection = TextSelection.collapsed(
                              offset: kw.length);
                          _search(kw);
                        },
                        onDeleted: () async {
                          // 单条删除：从 SearchHistory 表按 keyword 查找
                          try {
                            final row = await DatabaseHolder.instance
                                .getSearchHistoryByKeyword(kw);
                            if (row != null) {
                              await DatabaseHolder.instance
                                  .deleteSearchHistoryById(row.id);
                              ref.invalidate(localSearchHistoryProvider);
                            }
                          } catch (_) {}
                        },
                      ),
                    )
                    .toList(),
              ),
            );
          },
        ),
      ],
    );
  }
}
