import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/comic_model.dart';

/// 下载管理 Provider（简化版）
final downloadListProvider = StateProvider<List<DownloadTask>>((ref) => []);

/// 下载状态
enum DownloadStatus { pending, downloading, completed, failed }

/// 下载任务
class DownloadTask {
  final String comicId;
  final String comicTitle;
  final String episodeId;
  final String episodeTitle;
  final DownloadStatus status;
  final int progress; // 0-100
  final String? localPath;

  const DownloadTask({
    required this.comicId,
    required this.comicTitle,
    required this.episodeId,
    required this.episodeTitle,
    this.status = DownloadStatus.pending,
    this.progress = 0,
    this.localPath,
  });

  DownloadTask copyWith({
    String? comicId,
    String? comicTitle,
    String? episodeId,
    String? episodeTitle,
    DownloadStatus? status,
    int? progress,
    String? localPath,
  }) =>
      DownloadTask(
        comicId: comicId ?? this.comicId,
        comicTitle: comicTitle ?? this.comicTitle,
        episodeId: episodeId ?? this.episodeId,
        episodeTitle: episodeTitle ?? this.episodeTitle,
        status: status ?? this.status,
        progress: progress ?? this.progress,
        localPath: localPath ?? this.localPath,
      );
}

/// 下载管理界面
class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloads = ref.watch(downloadListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('下载管理'),
        actions: [
          if (downloads.isNotEmpty)
            TextButton(
              onPressed: () {
                ref.read(downloadListProvider.notifier).state = [];
              },
              child: const Text('清空'),
            ),
        ],
      ),
      body: downloads.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.download_done, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('暂无下载任务', style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 8),
                  Text(
                    '在漫画详情页点击下载按钮',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: downloads.length,
              itemBuilder: (context, index) {
                final task = downloads[index];
                return _DownloadTile(task: task);
              },
            ),
    );
  }
}

class _DownloadTile extends ConsumerWidget {
  final DownloadTask task;

  const _DownloadTile({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    IconData icon;
    Color color;

    switch (task.status) {
      case DownloadStatus.pending:
        icon = Icons.hourglass_empty;
        color = Colors.orange;
        break;
      case DownloadStatus.downloading:
        icon = Icons.downloading;
        color = Colors.blue;
        break;
      case DownloadStatus.completed:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case DownloadStatus.failed:
        icon = Icons.error;
        color = Colors.red;
        break;
    }

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(task.comicTitle),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(task.episodeTitle),
          if (task.status == DownloadStatus.downloading)
            LinearProgressIndicator(value: task.progress / 100),
        ],
      ),
      trailing: task.status == DownloadStatus.downloading
          ? IconButton(
              icon: const Icon(Icons.pause),
              onPressed: () {
                // TODO: 暂停下载
              },
            )
          : null,
    );
  }
}
