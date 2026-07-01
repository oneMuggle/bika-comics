import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/constants/app_colors.dart';
import '../../../shared/widgets/comic_card.dart';
import '../data/batch_search_repository.dart';
import '../data/forbid_words_filter_helper.dart';
import 'comic_detail_screen.dart';

/// 批量搜索工具
///
/// 对应桌面端 `view/tool/batch_sr_tool_view.py`（批量处理工具思路）的移动端迁移：
/// - 桌面端是 Waifu2x 批量图片放大（与移动端 GPU/性能场景不匹配）
/// - 移动端改为「批量搜索」：用户输入一组关键词，一键顺序搜索，结果可逐条查看
class BatchSearchScreen extends ConsumerStatefulWidget {
  const BatchSearchScreen({super.key});

  @override
  ConsumerState<BatchSearchScreen> createState() => _BatchSearchScreenState();
}

class _BatchSearchScreenState extends ConsumerState<BatchSearchScreen> {
  final TextEditingController _input = TextEditingController();
  final TextEditingController _bulk = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    _bulk.dispose();
    super.dispose();
  }

  void _add() {
    final v = _input.text.trim();
    if (v.isEmpty) return;
    ref.read(batchSearchProvider.notifier).addKeyword(v);
    _input.clear();
  }

  void _bulkAdd() {
    final raw = _bulk.text.trim();
    if (raw.isEmpty) return;
    final lines = raw
        .split(RegExp(r'[\n,，;；\s]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final notifier = ref.read(batchSearchProvider.notifier);
    for (final l in lines) {
      notifier.addKeyword(l);
    }
    _bulk.clear();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(batchSearchProvider);
    final notifier = ref.read(batchSearchProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('批量搜索工具'),
        actions: [
          IconButton(
            tooltip: '清空',
            icon: const Icon(Icons.delete_sweep),
            onPressed: state.items.isEmpty ? null : notifier.clear,
          ),
        ],
      ),
      body: Column(
        children: [
          // ============= 输入区 =============
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        decoration: const InputDecoration(
                          labelText: '添加关键词',
                          hintText: '输入一个关键词后回车',
                          prefixIcon: Icon(Icons.add),
                        ),
                        onSubmitted: (_) => _add(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(onPressed: _add, child: const Text('添加')),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _bulk,
                        maxLines: 3,
                        minLines: 1,
                        decoration: const InputDecoration(
                          labelText: '批量粘贴（每行 / 空格 / 逗号分隔）',
                          hintText: '碧蓝幻想\n純愛\n後宮閃光',
                          prefixIcon: Icon(Icons.paste),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonal(
                      onPressed: _bulkAdd,
                      child: const Text('解析'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: state.items.isEmpty || state.isRunning
                        ? null
                        : notifier.runAll,
                    icon: state.isRunning
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.play_arrow),
                    label: Text(state.isRunning ? '搜索中…' : '开始批量搜索'),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ============= 结果区 =============
          Expanded(
            child: state.items.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        '添加 1 个或多个关键词，然后点击「开始批量搜索」',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.secondaryText),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: state.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final item = state.items[i];
                      return _BatchItemCard(
                        item: item,
                        onRemove: state.isRunning
                            ? null
                            : () => notifier.removeKeyword(item.keyword),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _BatchItemCard extends ConsumerWidget {
  final BatchSearchItem item;
  final VoidCallback? onRemove;
  const _BatchItemCard({required this.item, this.onRemove});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 屏蔽词过滤
    final filteredResults = ref.watch(filteredComicsProvider(item.results));
    return Card(
      child: ExpansionTile(
        leading: item.isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : item.error != null
                ? const Icon(Icons.error, color: Colors.redAccent)
                : const Icon(Icons.search, color: Colors.green),
        title: Text(
          item.keyword,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          item.isLoading
              ? '搜索中…'
              : item.error != null
                  ? '失败：${item.error}'
                  : item.finishedAt == null
                      ? '等待'
                      : '共 ${filteredResults.length} 个结果',
          style: TextStyle(
            color: item.error != null ? Colors.redAccent : null,
            fontSize: 12,
          ),
        ),
        trailing: onRemove == null
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: onRemove,
                tooltip: '删除',
              ),
        children: [
          if (filteredResults.isEmpty && !item.isLoading && item.error == null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                item.results.isEmpty ? '无结果' : '全部结果已被屏蔽词过滤',
                style: const TextStyle(color: AppColors.secondaryText),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(8),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.62,
              ),
              itemCount: filteredResults.length,
              itemBuilder: (context, index) {
                final c = filteredResults[index];
                return ComicCard(
                  id: c.id,
                  title: c.title,
                  coverUrl: c.coverUrl,
                  subtitle: c.author.isEmpty ? null : c.author,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ComicDetailScreen(comicId: c.id),
                      ),
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}
