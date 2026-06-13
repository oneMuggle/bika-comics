import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database.dart';
import '../../../shared/constants/app_colors.dart';
import '../../export/presentation/export_screen.dart';
import '../data/download_repository.dart';

/// 下载管理页面
class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({super.key});

  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen> {
  bool _isSelectionMode = false;
  final Set<String> _selectedItems = {};

  @override
  Widget build(BuildContext context) {
    final downloadsState = ref.watch(downloadStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isSelectionMode
            ? '已选择 ${_selectedItems.length} 项'
            : '下载管理'),
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _isSelectionMode = false;
                    _selectedItems.clear();
                  });
                },
              )
            : null,
        actions: [
          if (!_isSelectionMode) ...[
            // 全部暂停/恢复按钮
            downloadsState.when(
              data: (downloads) {
                if (downloads.isEmpty) return const SizedBox.shrink();
                final hasActive = downloads.any(
                    (d) => d.status == DownloadTaskStatus.downloading);
                return TextButton.icon(
                  onPressed: () {
                    if (hasActive) {
                      ref.read(downloadStateProvider.notifier).pauseAll();
                    } else {
                      ref.read(downloadStateProvider.notifier).resumeAll();
                    }
                  },
                  icon: Icon(hasActive ? Icons.pause : Icons.play_arrow),
                  label: Text(hasActive ? '全部暂停' : '全部恢复'),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            // 清空已完成
            downloadsState.when(
              data: (downloads) {
                final completed = downloads
                    .where((d) => d.status == DownloadTaskStatus.completed)
                    .toList();
                if (completed.isEmpty) return const SizedBox.shrink();
                return TextButton.icon(
                  onPressed: () => _showClearCompletedDialog(context, completed),
                  icon: const Icon(Icons.cleaning_services),
                  label: Text('清空(${completed.length})'),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ] else ...[
            // 选中模式的操作
            IconButton(
              onPressed: _selectedItems.isEmpty
                  ? null
                  : () => _deleteSelected(withFiles: false),
              icon: const Icon(Icons.delete_outline),
              tooltip: '删除记录',
            ),
            IconButton(
              onPressed: _selectedItems.isEmpty
                  ? null
                  : () => _deleteSelected(withFiles: true),
              icon: const Icon(Icons.delete_forever),
              tooltip: '删除记录和文件',
            ),
          ],
        ],
      ),
      body: downloadsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('加载失败: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(downloadStateProvider.notifier).refresh(),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
        data: (downloads) {
          if (downloads.isEmpty) {
            return _buildEmptyState();
          }
          return _buildDownloadList(downloads);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.download_done, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(
            '暂无下载任务',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '在漫画详情页点击下载按钮',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadList(List<DownloadTask> downloads) {
    // 按状态分组显示
    final downloading = downloads
        .where((d) => d.status == DownloadTaskStatus.downloading)
        .toList();
    final pending = downloads
        .where((d) => d.status == DownloadTaskStatus.pending)
        .toList();
    final paused = downloads
        .where((d) => d.status == DownloadTaskStatus.paused)
        .toList();
    final completed = downloads
        .where((d) => d.status == DownloadTaskStatus.completed)
        .toList();
    final failed = downloads
        .where((d) => d.status == DownloadTaskStatus.failed)
        .toList();

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(downloadStateProvider.notifier).refresh();
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          if (downloading.isNotEmpty) ...[
            _buildSectionHeader('下载中', Icons.downloading, Colors.blue),
            ...downloading.map((d) => _buildDownloadTile(d)),
          ],
          if (pending.isNotEmpty) ...[
            _buildSectionHeader('等待中', Icons.hourglass_empty, Colors.orange),
            ...pending.map((d) => _buildDownloadTile(d)),
          ],
          if (paused.isNotEmpty) ...[
            _buildSectionHeader('已暂停', Icons.pause_circle, Colors.grey),
            ...paused.map((d) => _buildDownloadTile(d)),
          ],
          if (failed.isNotEmpty) ...[
            _buildSectionHeader('失败', Icons.error, Colors.red),
            ...failed.map((d) => _buildDownloadTile(d)),
          ],
          if (completed.isNotEmpty) ...[
            _buildSectionHeader('已完成', Icons.check_circle, Colors.green),
            ...completed.map((d) => _buildDownloadTile(d)),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadTile(DownloadTask task) {
    final isSelected = _selectedItems.contains(task.comicId);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 1,
      child: InkWell(
        onTap: () => _showDownloadDetail(task),
        onLongPress: () {
          setState(() {
            _isSelectionMode = true;
            _selectedItems.add(task.comicId);
          });
        },
        child: Container(
          decoration: BoxDecoration(
            border: isSelected
                ? Border.all(color: Theme.of(context).primaryColor, width: 2)
                : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // 选中复选框
                if (_isSelectionMode)
                  Checkbox(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedItems.add(task.comicId);
                        } else {
                          _selectedItems.remove(task.comicId);
                        }
                      });
                    },
                  ),
                // 封面
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: task.coverUrl,
                    width: 60,
                    height: 80,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
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
                        task.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (task.author != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          task.author!,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.secondaryText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 6),
                      // 进度条
                      _buildProgressIndicator(task),
                      const SizedBox(height: 4),
                      // 状态文本
                      Text(
                        task.statusText,
                        style: TextStyle(
                          fontSize: 12,
                          color: _getStatusColor(task.status),
                        ),
                      ),
                    ],
                  ),
                ),
                // 操作按钮
                if (!_isSelectionMode) _buildActionButtons(task),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(DownloadTask task) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: task.progress,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor(task.status)),
        ),
        const SizedBox(height: 2),
        Text(
          '${task.completedEpisodes}/${task.totalEpisodes} 章节',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(DownloadTask task) {
    switch (task.status) {
      case DownloadTaskStatus.downloading:
        return IconButton(
          icon: const Icon(Icons.pause, color: Colors.orange),
          onPressed: () {
            ref.read(downloadStateProvider.notifier).pauseDownload(task.comicId);
          },
          tooltip: '暂停',
        );
      case DownloadTaskStatus.pending:
      case DownloadTaskStatus.paused:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.play_arrow, color: Colors.green),
              onPressed: () {
                ref.read(downloadStateProvider.notifier).resumeDownload(task.comicId);
              },
              tooltip: '恢复',
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () => _showCancelDialog(task),
              tooltip: '取消',
            ),
          ],
        );
      case DownloadTaskStatus.completed:
        return IconButton(
          icon: const Icon(Icons.check_circle, color: Colors.green),
          onPressed: () {},
          tooltip: '已完成',
        );
      case DownloadTaskStatus.failed:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.orange),
              onPressed: () {
                ref.read(downloadStateProvider.notifier).resumeDownload(task.comicId);
              },
              tooltip: '重试',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _showDeleteDialog(task),
              tooltip: '删除',
            ),
          ],
        );
    }
  }

  Color _getStatusColor(DownloadTaskStatus status) {
    switch (status) {
      case DownloadTaskStatus.pending:
        return Colors.orange;
      case DownloadTaskStatus.downloading:
        return Colors.blue;
      case DownloadTaskStatus.paused:
        return Colors.grey;
      case DownloadTaskStatus.completed:
        return Colors.green;
      case DownloadTaskStatus.failed:
        return Colors.red;
    }
  }

  void _showDownloadDetail(DownloadTask task) {
    if (_isSelectionMode) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _DownloadDetailSheet(task: task),
    );
  }

  void _showCancelDialog(DownloadTask task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('取消下载'),
        content: Text('确定取消下载《${task.title}》吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('否'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(downloadStateProvider.notifier).cancelDownload(task.comicId);
            },
            child: const Text('是'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(DownloadTask task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除下载'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('确定删除《${task.title}》的下载记录吗？'),
            const SizedBox(height: 8),
            const Text(
              '文件将保留在设备上',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(downloadStateProvider.notifier).deleteDownload(task.comicId);
            },
            child: const Text('删除记录'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(downloadStateProvider.notifier).deleteDownloadWithFiles(task.comicId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除记录和文件'),
          ),
        ],
      ),
    );
  }

  void _showClearCompletedDialog(BuildContext context, List<DownloadTask> completed) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空已完成'),
        content: Text('确定清空 ${completed.length} 个已完成的下载记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              for (final task in completed) {
                ref.read(downloadStateProvider.notifier).deleteDownload(task.comicId);
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _deleteSelected({required bool withFiles}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(withFiles ? '删除记录和文件' : '删除记录'),
        content: Text('确定删除选中的 ${_selectedItems.length} 个下载吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              for (final comicId in _selectedItems) {
                if (withFiles) {
                  ref.read(downloadStateProvider.notifier).deleteDownloadWithFiles(comicId);
                } else {
                  ref.read(downloadStateProvider.notifier).deleteDownload(comicId);
                }
              }
              setState(() {
                _isSelectionMode = false;
                _selectedItems.clear();
              });
            },
            style: TextButton.styleFrom(
              foregroundColor: withFiles ? Colors.red : null,
            ),
            child: Text(withFiles ? '删除记录和文件' : '删除记录'),
          ),
        ],
      ),
    );
  }
}

/// 下载详情底部面板
class _DownloadDetailSheet extends ConsumerWidget {
  final DownloadTask task;

  const _DownloadDetailSheet({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // 拖动条
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // 头部信息
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: task.coverUrl,
                        width: 80,
                        height: 110,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (task.author != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              task.author!,
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          // 标签
                          if (task.tags.isNotEmpty)
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: task.tags.take(3).map((tag) {
                                return Chip(
                                  label: Text(tag, style: const TextStyle(fontSize: 10)),
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // 进度信息
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('下载进度'),
                        Text(
                          '${task.completedEpisodes}/${task.totalEpisodes} 章节',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: task.progress,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getStatusColor(task.status),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          task.statusText,
                          style: TextStyle(
                            color: _getStatusColor(task.status),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${(task.progress * 100).toInt()}%',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // 操作按钮
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        context,
                        ref,
                        icon: task.status == DownloadTaskStatus.downloading
                            ? Icons.pause
                            : Icons.play_arrow,
                        label: task.status == DownloadTaskStatus.downloading
                            ? '暂停'
                            : '继续',
                        color: task.status == DownloadTaskStatus.downloading
                            ? Colors.orange
                            : Colors.green,
                        onPressed: () {
                          if (task.status == DownloadTaskStatus.downloading) {
                            ref.read(downloadStateProvider.notifier).pauseDownload(task.comicId);
                          } else {
                            ref.read(downloadStateProvider.notifier).resumeDownload(task.comicId);
                          }
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildActionButton(
                        context,
                        ref,
                        icon: Icons.ios_share,
                        label: '导出',
                        color: AppColors.primary,
                        onPressed: task.completedEpisodes == 0
                            ? null
                            : () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ExportScreen(
                                      comicId: task.comicId,
                                      comicTitle: task.title,
                                    ),
                                  ),
                                );
                              },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildActionButton(
                        context,
                        ref,
                        icon: Icons.delete_outline,
                        label: '删除',
                        color: Colors.red,
                        onPressed: () {
                          Navigator.pop(context);
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('删除下载'),
                              content: Text('确定删除《${task.title}》的下载吗？'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('取消'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    ref.read(downloadStateProvider.notifier).deleteDownload(task.comicId);
                                  },
                                  child: const Text('删除'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // 章节列表
              Expanded(
                child: _buildEpisodeList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildEpisodeList() {
    return FutureBuilder(
      future: _loadEpisodeProgress(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final episodes = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: episodes.length,
          itemBuilder: (context, index) {
            final episode = episodes[index];
            return ListTile(
              dense: true,
              leading: Icon(
                _getEpisodeIcon(episode.status),
                color: _getStatusColor(episode.status),
                size: 20,
              ),
              title: Text(
                episode.episodeTitle,
                style: const TextStyle(fontSize: 14),
              ),
              subtitle: episode.status == DownloadTaskStatus.downloading
                  ? LinearProgressIndicator(value: episode.progress / 100)
                  : null,
              trailing: Text(
                episode.status == DownloadTaskStatus.completed
                    ? '已完成'
                    : '${episode.downloadedPages}/${episode.totalPages}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<List<EpisodeDownloadProgress>> _loadEpisodeProgress() async {
    final db = DatabaseHolder.instance;
    final download = await db.getDownloadByComicId(task.comicId);
    if (download == null) return [];

    final progress = await db.getProgressForDownload(download.id);
    return progress.map((p) => EpisodeDownloadProgress.fromDatabase(p)).toList();
  }

  IconData _getEpisodeIcon(DownloadTaskStatus status) {
    switch (status) {
      case DownloadTaskStatus.pending:
        return Icons.hourglass_empty;
      case DownloadTaskStatus.downloading:
        return Icons.downloading;
      case DownloadTaskStatus.paused:
        return Icons.pause_circle_outline;
      case DownloadTaskStatus.completed:
        return Icons.check_circle;
      case DownloadTaskStatus.failed:
        return Icons.error;
    }
  }

  Color _getStatusColor(DownloadTaskStatus status) {
    switch (status) {
      case DownloadTaskStatus.pending:
        return Colors.orange;
      case DownloadTaskStatus.downloading:
        return Colors.blue;
      case DownloadTaskStatus.paused:
        return Colors.grey;
      case DownloadTaskStatus.completed:
        return Colors.green;
      case DownloadTaskStatus.failed:
        return Colors.red;
    }
  }
}
