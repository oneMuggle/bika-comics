import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database.dart';
import '../../../shared/constants/app_colors.dart';
import '../../comic/presentation/comic_detail_screen.dart';

/// 历史记录 Provider
/// Returns list of (history entry, remote comicId) tuples
final historyProvider = FutureProvider<List<HistoryWithRemoteId>>((ref) async {
  final db = DatabaseHolder.instance;
  final historyList = await db.getRecentHistory(limit: 100);
  final result = <HistoryWithRemoteId>[];

  for (final h in historyList) {
    // Try to find local comic by local id first
    final localComic = await db.getComicById(h.comicId);
    result.add(HistoryWithRemoteId(
      history: h,
      remoteId: localComic?.comicId,
      title: localComic?.title ?? '未知漫画',
      coverUrl: localComic?.coverUrl ?? '',
    ));
  }
  return result;
});

/// 历史记录 + 远程漫画ID
class HistoryWithRemoteId {
  final HistoryData history;
  final String? remoteId;
  final String title;
  final String coverUrl;

  HistoryWithRemoteId({
    required this.history,
    required this.remoteId,
    required this.title,
    required this.coverUrl,
  });
}

/// 阅读历史页
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncHistory = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('阅读历史'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('清空历史'),
                  content: const Text('确定要清空所有阅读历史吗？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('取消'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('确定'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                final db = DatabaseHolder.instance;
                await db.clearAllHistory();
                ref.invalidate(historyProvider);
              }
            },
          ),
        ],
      ),
      body: asyncHistory.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('加载失败: $e'),
              FilledButton(
                onPressed: () => ref.invalidate(historyProvider),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
        data: (records) => records.isEmpty
            ? const Center(child: Text('暂无阅读历史'))
            : RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(historyProvider);
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    return _HistoryTile(
                      record: records[index],
                      onDelete: () async {
                        final db = DatabaseHolder.instance;
                        await db.deleteHistory(records[index].history.id);
                        ref.invalidate(historyProvider);
                      },
                    );
                  },
                ),
              ),
      ),
    );
  }
}

/// 单条历史记录
class _HistoryTile extends StatelessWidget {
  final HistoryWithRemoteId record;
  final VoidCallback onDelete;

  const _HistoryTile({required this.record, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final title = record.title;
    final coverUrl = record.coverUrl;
    final history = record.history;
    final readAt = history.lastReadAt;
    final remoteId = record.remoteId;

    return Dismissible(
      key: Key('history_${history.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: remoteId != null
              ? () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ComicDetailScreen(comicId: remoteId),
                    ),
                  );
                }
              : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // 封面
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: coverUrl,
                    width: 60,
                    height: 80,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 60,
                      height: 80,
                      color: AppColors.darkCard,
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 60,
                      height: 80,
                      color: AppColors.darkCard,
                      child: const Icon(Icons.broken_image),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // 信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '看到第 ${history.lastPage + 1} 页',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withAlpha(180),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(readAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withAlpha(130),
                        ),
                      ),
                    ],
                  ),
                ),
                // 删除按钮
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}天前';
    if (diff.inHours > 0) return '${diff.inHours}小时前';
    if (diff.inMinutes > 0) return '${diff.inMinutes}分钟前';
    return '刚刚';
  }
}
