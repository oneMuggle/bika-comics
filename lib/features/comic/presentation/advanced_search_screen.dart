import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/constants/app_colors.dart';
import '../../../shared/widgets/comic_card.dart';
import '../data/comic_repository.dart';
import '../domain/comic_model.dart';
import 'categories_screen.dart' show Category, categoriesProvider;
import 'comic_detail_screen.dart';

/// 高级搜索页面
/// 支持多分类组合 + 关键词 + 排序
class AdvancedSearchScreen extends ConsumerStatefulWidget {
  const AdvancedSearchScreen({super.key});

  @override
  ConsumerState<AdvancedSearchScreen> createState() =>
      _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends ConsumerState<AdvancedSearchScreen> {
  final _keywordCtrl = TextEditingController();
  final Set<String> _selectedCategoryIds = <String>{};
  String _sort = '';

  List<Comic>? _results;
  bool _loading = false;
  String? _error;

  static const _sortOptions = <(String, String)>[
    ('', '默认'),
    ('dd', '最新'),
    ('da', '最旧'),
    ('ld', '最多喜欢'),
    ('vd', '最多浏览'),
  ];

  @override
  void dispose() {
    _keywordCtrl.dispose();
    super.dispose();
  }

  Future<void> _doSearch() async {
    final keyword = _keywordCtrl.text.trim();
    if (keyword.isEmpty && _selectedCategoryIds.isEmpty) {
      setState(() => _error = '请输入关键词或选择分类');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(comicRepositoryProvider);
      final results = await repo.advancedSearch(
        keyword: keyword,
        categories: _selectedCategoryIds.toList(),
        sort: _sort,
      );
      if (mounted) {
        setState(() {
          _results = results;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _loading = false;
        });
      }
    }
  }

  void _clearFilters() {
    setState(() {
      _keywordCtrl.clear();
      _selectedCategoryIds.clear();
      _sort = '';
      _results = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncCategories = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('高级搜索'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '清空筛选',
            onPressed: _clearFilters,
          ),
        ],
      ),
      body: Column(
        children: [
          // 关键词输入
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _keywordCtrl,
              decoration: InputDecoration(
                labelText: '关键词',
                hintText: '可留空，仅按分类筛选',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: _keywordCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _keywordCtrl.clear()),
                      ),
              ),
              onSubmitted: (_) => _doSearch(),
            ),
          ),

          // 排序
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                ..._sortOptions.map((s) {
                  final selected = _sort == s.$1;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(s.$2),
                      selected: selected,
                      onSelected: (_) => setState(() => _sort = s.$1),
                    ),
                  );
                }),
              ],
            ),
          ),

          // 分类多选
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(
              children: [
                Icon(Icons.category, color: AppColors.primary, size: 18),
                const SizedBox(width: 6),
                Text(
                  '选择分类 (${_selectedCategoryIds.length} 已选)',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: asyncCategories.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('加载分类失败: $e'),
                ),
              ),
              data: (categories) => SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: categories.map((c) {
                    final selected = _selectedCategoryIds.contains(c.id);
                    return FilterChip(
                      label: Text(c.title),
                      selected: selected,
                      onSelected: (sel) {
                        setState(() {
                          if (sel) {
                            _selectedCategoryIds.add(c.id);
                          } else {
                            _selectedCategoryIds.remove(c.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          // 搜索按钮
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: FilledButton.icon(
              onPressed: _loading ? null : _doSearch,
              icon: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.search),
              label: Text(_loading ? '搜索中…' : '开始搜索'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
            ),
          ),

          // 错误/结果区
          Expanded(
            flex: 3,
            child: _buildResultArea(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultArea() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_results == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('输入关键词或选择分类，开始搜索',
              style: TextStyle(color: Colors.grey)),
        ),
      );
    }
    if (_results!.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('未找到匹配的漫画', style: TextStyle(color: Colors.grey)),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.6,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _results!.length,
      itemBuilder: (context, index) {
        final comic = _results![index];
        return ComicCard(
          id: comic.id,
          title: comic.title,
          coverUrl: comic.coverUrl,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ComicDetailScreen(comicId: comic.id),
            ),
          ),
        );
      },
    );
  }
}
