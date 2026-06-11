import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/db/database.dart';
import '../../../shared/constants/api_constants.dart';

/// 下载状态枚举
enum DownloadTaskStatus {
  pending('pending'),      // 等待中
  downloading('downloading'),  // 下载中
  paused('paused'),       // 已暂停
  completed('completed'), // 已完成
  failed('failed');      // 失败

  final String value;
  const DownloadTaskStatus(this.value);

  static DownloadTaskStatus fromString(String value) {
    return DownloadTaskStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => DownloadTaskStatus.pending,
    );
  }
}

/// 下载任务模型
class DownloadTask {
  final String comicId;
  final String title;
  final String coverUrl;
  final String? author;
  final List<String> tags;
  final List<String> downloadedEpisodeIds;
  final List<String> pendingEpisodeIds;
  final DownloadTaskStatus status;
  final int totalEpisodes;
  final int completedEpisodes;
  final int currentEpisodeIndex;
  final String? currentEpisodeId;
  final String? localPath;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;

  const DownloadTask({
    required this.comicId,
    required this.title,
    required this.coverUrl,
    this.author,
    this.tags = const [],
    this.downloadedEpisodeIds = const [],
    this.pendingEpisodeIds = const [],
    this.status = DownloadTaskStatus.pending,
    this.totalEpisodes = 0,
    this.completedEpisodes = 0,
    this.currentEpisodeIndex = 0,
    this.currentEpisodeId,
    this.localPath,
    required this.createdAt,
    this.updatedAt,
    this.completedAt,
  });

  double get progress => totalEpisodes > 0 ? completedEpisodes / totalEpisodes : 0;

  String get statusText {
    switch (status) {
      case DownloadTaskStatus.pending:
        return '等待中';
      case DownloadTaskStatus.downloading:
        return '下载中 $completedEpisodes/$totalEpisodes';
      case DownloadTaskStatus.paused:
        return '已暂停';
      case DownloadTaskStatus.completed:
        return '已完成';
      case DownloadTaskStatus.failed:
        return '失败';
    }
  }

  factory DownloadTask.fromDatabase(Download download) {
    return DownloadTask(
      comicId: download.comicId,
      title: download.title,
      coverUrl: download.coverUrl,
      author: download.author,
      tags: download.tags?.split(',') ?? [],
      downloadedEpisodeIds: _parseJsonList(download.downloadedEpisodeIds),
      pendingEpisodeIds: _parseJsonList(download.pendingEpisodeIds),
      status: DownloadTaskStatus.fromString(download.status),
      totalEpisodes: download.totalEpisodes,
      completedEpisodes: download.completedEpisodes,
      currentEpisodeIndex: download.currentEpisodeIndex,
      currentEpisodeId: download.currentEpisodeId,
      localPath: download.localPath,
      createdAt: download.createdAt,
      updatedAt: download.updatedAt,
      completedAt: download.completedAt,
    );
  }

  static List<String> _parseJsonList(String jsonStr) {
    try {
      final decoded = json.decode(jsonStr);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
    } catch (_) {}
    return [];
  }

  DownloadTask copyWith({
    String? comicId,
    String? title,
    String? coverUrl,
    String? author,
    List<String>? tags,
    List<String>? downloadedEpisodeIds,
    List<String>? pendingEpisodeIds,
    DownloadTaskStatus? status,
    int? totalEpisodes,
    int? completedEpisodes,
    int? currentEpisodeIndex,
    String? currentEpisodeId,
    String? localPath,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return DownloadTask(
      comicId: comicId ?? this.comicId,
      title: title ?? this.title,
      coverUrl: coverUrl ?? this.coverUrl,
      author: author ?? this.author,
      tags: tags ?? this.tags,
      downloadedEpisodeIds: downloadedEpisodeIds ?? this.downloadedEpisodeIds,
      pendingEpisodeIds: pendingEpisodeIds ?? this.pendingEpisodeIds,
      status: status ?? this.status,
      totalEpisodes: totalEpisodes ?? this.totalEpisodes,
      completedEpisodes: completedEpisodes ?? this.completedEpisodes,
      currentEpisodeIndex: currentEpisodeIndex ?? this.currentEpisodeIndex,
      currentEpisodeId: currentEpisodeId ?? this.currentEpisodeId,
      localPath: localPath ?? this.localPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

/// 单章节下载进度
class EpisodeDownloadProgress {
  final String episodeId;
  final String episodeTitle;
  final int totalPages;
  final int downloadedPages;
  final DownloadTaskStatus status;
  final int progress;

  const EpisodeDownloadProgress({
    required this.episodeId,
    required this.episodeTitle,
    this.totalPages = 0,
    this.downloadedPages = 0,
    this.status = DownloadTaskStatus.pending,
    this.progress = 0,
  });

  factory EpisodeDownloadProgress.fromDatabase(DownloadProgressData data) {
    return EpisodeDownloadProgress(
      episodeId: data.episodeId,
      episodeTitle: data.episodeTitle,
      totalPages: data.totalPages,
      downloadedPages: data.downloadedPages,
      status: DownloadTaskStatus.fromString(data.status),
      progress: data.progress,
    );
  }
}

/// 下载仓库
class DownloadRepository {
  final AppDatabase _db;
  final Dio _api = ApiClient.instance;

  // 下载队列
  final List<DownloadTask> _downloadQueue = [];
  int _maxConcurrentDownloads = 2;
  final Map<String, CancelToken> _cancelTokens = {};
  final Map<String, bool> _pausedTasks = {};

  // 进度流
  final _progressController = StreamController<DownloadProgressEvent>.broadcast();
  Stream<DownloadProgressEvent> get progressStream => _progressController.stream;

  DownloadRepository(this._db);

  /// 获取所有下载任务
  Future<List<DownloadTask>> getAllDownloads() async {
    final downloads = await _db.getAllDownloads();
    return downloads.map((d) => DownloadTask.fromDatabase(d)).toList();
  }

  /// 获取活跃的下载任务
  Future<List<DownloadTask>> getActiveDownloads() async {
    final downloads = await _db.getActiveDownloads();
    return downloads.map((d) => DownloadTask.fromDatabase(d)).toList();
  }

  /// 获取暂停的下载任务
  Future<List<DownloadTask>> getPausedDownloads() async {
    final downloads = await _db.getPausedDownloads();
    return downloads.map((d) => DownloadTask.fromDatabase(d)).toList();
  }

  /// 获取单个下载任务
  Future<DownloadTask?> getDownload(String comicId) async {
    final download = await _db.getDownloadByComicId(comicId);
    return download != null ? DownloadTask.fromDatabase(download) : null;
  }

  /// 获取章节下载进度
  Future<List<EpisodeDownloadProgress>> getEpisodeProgress(int downloadId) async {
    final progress = await _db.getProgressForDownload(downloadId);
    return progress.map((p) => EpisodeDownloadProgress.fromDatabase(p)).toList();
  }

  /// 添加下载任务 - 下载整本漫画
  Future<void> addDownload({
    required String comicId,
    required String title,
    required String coverUrl,
    String? author,
    List<String>? tags,
    required List<String> episodeIds,
    required List<String> episodeTitles,
  }) async {
    // 检查是否已存在
    final existing = await _db.getDownloadByComicId(comicId);
    if (existing != null) {
      // 更新待下载列表，添加新章节
      final existingTask = DownloadTask.fromDatabase(existing);
      final mergedPending = {...existingTask.pendingEpisodeIds, ...episodeIds}.toList();
      await _db.updateDownloadStatus(
        comicId,
        existingTask.status.value,
        localPath: existingTask.localPath,
      );
      // 更新pendingEpisodeIds
      final download = await _db.getDownloadByComicId(comicId);
      if (download != null) {
        await _db.customStatement(
          "UPDATE downloads SET pendingEpisodeIds = '${json.encode(mergedPending)}', totalEpisodes = ${mergedPending.length + existingTask.completedEpisodes} WHERE comicId = '$comicId'",
        );
      }
      return;
    }

    // 创建新任务
    final now = DateTime.now();
    await _db.insertDownload(DownloadsCompanion(
      comicId: Value(comicId),
      title: Value(title),
      coverUrl: Value(coverUrl),
      author: Value(author),
      tags: Value(tags?.join(',') ?? ''),
      downloadedEpisodeIds: Value(json.encode([])),
      pendingEpisodeIds: Value(json.encode(episodeIds)),
      status: Value(DownloadTaskStatus.pending.value),
      totalEpisodes: Value(episodeIds.length),
      completedEpisodes: const Value(0),
      currentEpisodeIndex: const Value(0),
      createdAt: Value(now),
    ));

    // 初始化每个章节的进度
    final download = await _db.getDownloadByComicId(comicId);
    if (download != null) {
      for (int i = 0; i < episodeIds.length; i++) {
        await _db.insertDownloadProgress(DownloadProgressCompanion(
          downloadId: Value(download.id),
          episodeId: Value(episodeIds[i]),
          episodeTitle: Value(episodeTitles[i]),
          totalPages: const Value(0),
          downloadedPages: const Value(0),
          status: Value(DownloadTaskStatus.pending.value),
          progress: const Value(0),
          createdAt: Value(now),
        ));
      }
    }

    // 如果队列未满，启动下载
    _startNextDownload();
  }

  /// 添加单个章节下载
  Future<void> addEpisodeDownload({
    required String comicId,
    required String episodeId,
    required String episodeTitle,
    required String title,
    required String coverUrl,
  }) async {
    final existing = await _db.getDownloadByComicId(comicId);
    if (existing != null) {
      final task = DownloadTask.fromDatabase(existing);
      if (!task.pendingEpisodeIds.contains(episodeId) && !task.downloadedEpisodeIds.contains(episodeId)) {
        final newPending = [...task.pendingEpisodeIds, episodeId];
        await _db.customStatement(
          "UPDATE downloads SET pendingEpisodeIds = '${json.encode(newPending)}', totalEpisodes = ${newPending.length + task.completedEpisodes} WHERE comicId = '$comicId'",
        );
      }
    } else {
      final now = DateTime.now();
      await _db.insertDownload(DownloadsCompanion(
        comicId: Value(comicId),
        title: Value(title),
        coverUrl: Value(coverUrl),
        downloadedEpisodeIds: Value(json.encode([])),
        pendingEpisodeIds: Value(json.encode([episodeId])),
        status: Value(DownloadTaskStatus.pending.value),
        totalEpisodes: const Value(1),
        completedEpisodes: const Value(0),
        currentEpisodeIndex: const Value(0),
        createdAt: Value(now),
      ));

      final download = await _db.getDownloadByComicId(comicId);
      if (download != null) {
        await _db.insertDownloadProgress(DownloadProgressCompanion(
          downloadId: Value(download.id),
          episodeId: Value(episodeId),
          episodeTitle: Value(episodeTitle),
          totalPages: const Value(0),
          downloadedPages: const Value(0),
          status: Value(DownloadTaskStatus.pending.value),
          progress: const Value(0),
          createdAt: Value(now),
        ));
      }
    }
    _startNextDownload();
  }

  /// 暂停指定下载
  Future<void> pauseDownload(String comicId) async {
    _pausedTasks[comicId] = true;
    _cancelTokens[comicId]?.cancel('Paused by user');
    await _db.updateDownloadStatus(comicId, DownloadTaskStatus.paused.value);
    _progressController.add(DownloadProgressEvent(
      comicId: comicId,
      status: DownloadTaskStatus.paused,
    ));
  }

  /// 恢复指定下载
  Future<void> resumeDownload(String comicId) async {
    _pausedTasks.remove(comicId);
    final download = await _db.getDownloadByComicId(comicId);
    if (download != null) {
      await _db.updateDownloadStatus(comicId, DownloadTaskStatus.pending.value);
      _startNextDownload();
    }
  }

  /// 取消指定下载
  Future<void> cancelDownload(String comicId) async {
    _cancelTokens[comicId]?.cancel('Cancelled by user');
    _cancelTokens.remove(comicId);
    _pausedTasks.remove(comicId);

    final download = await _db.getDownloadByComicId(comicId);
    if (download != null) {
      await _db.deleteProgressForDownload(download.id);
      await _db.deleteDownloadByComicId(comicId);
    }
    _progressController.add(DownloadProgressEvent(
      comicId: comicId,
      status: DownloadTaskStatus.failed,
      isCancelled: true,
    ));
  }

  /// 暂停所有下载
  Future<void> pauseAll() async {
    for (final token in _cancelTokens.values) {
      token.cancel('Paused all');
    }
    _cancelTokens.clear();
    _pausedTasks.clear();

    final downloads = await getActiveDownloads();
    for (final download in downloads) {
      await _db.updateDownloadStatus(download.comicId, DownloadTaskStatus.paused.value);
      _progressController.add(DownloadProgressEvent(
        comicId: download.comicId,
        status: DownloadTaskStatus.paused,
      ));
    }
  }

  /// 恢复所有下载
  Future<void> resumeAll() async {
    final downloads = await getPausedDownloads();
    for (final download in downloads) {
      _pausedTasks.remove(download.comicId);
      await _db.updateDownloadStatus(download.comicId, DownloadTaskStatus.pending.value);
    }
    // 重新启动队列
    for (int i = 0; i < _maxConcurrentDownloads; i++) {
      _startNextDownload();
    }
  }

  /// 删除下载记录（保留文件）
  Future<void> deleteDownload(String comicId) async {
    await cancelDownload(comicId);
    // 文件保留，仅删除数据库记录
  }

  /// 删除下载记录和文件
  Future<void> deleteDownloadWithFiles(String comicId) async {
    await cancelDownload(comicId);
    final download = await getDownload(comicId);
    if (download?.localPath != null) {
      final dir = Directory(download!.localPath!);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    }
  }

  /// 设置最大并发数
  void setMaxConcurrentDownloads(int max) {
    _maxConcurrentDownloads = max;
  }

  /// 启动下一个下载任务
  void _startNextDownload() {
    if (_pausedTasks.isNotEmpty) return;

    final activeCount = _cancelTokens.length;
    if (activeCount >= _maxConcurrentDownloads) return;

    // 从pending任务中获取下一个
    _processNextPending();
  }

  Future<void> _processNextPending() async {
    final downloads = await _db.getPendingDownloads();
    for (final download in downloads) {
      if (_cancelTokens.containsKey(download.comicId)) continue;
      if (_pausedTasks.containsKey(download.comicId)) continue;
      _downloadQueue.add(DownloadTask.fromDatabase(download));
    }

    while (_downloadQueue.isNotEmpty && _cancelTokens.length < _maxConcurrentDownloads) {
      final task = _downloadQueue.removeAt(0);
      if (_pausedTasks.containsKey(task.comicId)) continue;
      _executeDownload(task);
    }
  }

  /// 执行下载
  Future<void> _executeDownload(DownloadTask task) async {
    final cancelToken = CancelToken();
    _cancelTokens[task.comicId] = cancelToken;

    await _db.updateDownloadStatus(task.comicId, DownloadTaskStatus.downloading.value);

    // 解析待下载章节
    List<String> pendingIds;
    try {
      pendingIds = List<String>.from(json.decode(json.encode(task.pendingEpisodeIds)));
    } catch (_) {
      pendingIds = [];
    }

    if (pendingIds.isEmpty) {
      await _db.updateDownloadStatus(task.comicId, DownloadTaskStatus.completed.value);
      _cancelTokens.remove(task.comicId);
      return;
    }

    // 获取本地保存路径
    final appDir = await getApplicationDocumentsDirectory();
    final savePath = '${appDir.path}/downloads/${task.comicId}';
    await Directory(savePath).create(recursive: true);

    // 遍历下载所有待下载章节
    for (final episodeId in pendingIds) {
      if (cancelToken.isCancelled) break;
      if (_pausedTasks.containsKey(task.comicId)) break;

      try {
        // 获取章节图片
        final response = await _api.get(
          ApiEndpoints.episodePages(task.comicId, episodeId),
          cancelToken: cancelToken,
        );

        final data = response.data['data'];
        final pages = data['pages']['docs'] as List;
        final totalPages = pages.length;

        // 更新章节总页数
        final download = await _db.getDownloadByComicId(task.comicId);
        if (download != null) {
          await _db.customStatement(
            "UPDATE download_progress SET totalPages = $totalPages WHERE downloadId = ${download.id} AND episodeId = '$episodeId'",
          );
        }

        // 创建章节目录
        final epsDir = Directory('$savePath/$episodeId');
        await epsDir.create(recursive: true);

        // 下载每一页
        for (int i = 0; i < pages.length; i++) {
          if (cancelToken.isCancelled) break;
          if (_pausedTasks.containsKey(task.comicId)) break;

          final page = pages[i];
          final imageUrl = page['path'] ?? page['url'] ?? '';
          if (imageUrl.isEmpty) continue;

          // 下载图片
          await _downloadImage(
            imageUrl: imageUrl,
            savePath: '$savePath/$episodeId/${i.toString().padLeft(4, '0')}.jpg',
            cancelToken: cancelToken,
          );

          // 更新进度
          final downloadedPages = i + 1;
          final progress = ((downloadedPages / totalPages) * 100).round();
          if (download != null) {
            await _db.updateDownloadProgress(download.id, episodeId,
              downloadedPages: downloadedPages,
              progress: progress,
              status: DownloadTaskStatus.downloading.value,
            );
          }

          _progressController.add(DownloadProgressEvent(
            comicId: task.comicId,
            episodeId: episodeId,
            status: DownloadTaskStatus.downloading,
            progress: progress,
            downloadedPages: downloadedPages,
            totalPages: totalPages,
          ));
        }

        // 章节下载完成
        if (download != null) {
          await _db.updateDownloadProgress(download.id, episodeId,
            downloadedPages: totalPages,
            progress: 100,
            status: DownloadTaskStatus.completed.value,
          );
        }

      } on DioException catch (e) {
        if (e.type == DioExceptionType.cancel) {
          // 被取消
          return;
        }
        // 下载失败，标记章节为failed
        final download = await _db.getDownloadByComicId(task.comicId);
        if (download != null) {
          await _db.updateDownloadProgress(download.id, episodeId,
            status: DownloadTaskStatus.failed.value,
          );
        }
        _progressController.add(DownloadProgressEvent(
          comicId: task.comicId,
          episodeId: episodeId,
          status: DownloadTaskStatus.failed,
          error: e.message,
        ));
      } catch (e) {
        // 其他错误
        _progressController.add(DownloadProgressEvent(
          comicId: task.comicId,
          episodeId: episodeId,
          status: DownloadTaskStatus.failed,
          error: e.toString(),
        ));
      }
    }

    // 全部完成
    await _db.updateDownloadStatus(
      task.comicId,
      DownloadTaskStatus.completed.value,
      completedEpisodes: task.totalEpisodes,
      localPath: savePath,
    );
    _cancelTokens.remove(task.comicId);

    _progressController.add(DownloadProgressEvent(
      comicId: task.comicId,
      status: DownloadTaskStatus.completed,
    ));
  }

  /// 下载单张图片
  Future<void> _downloadImage({
    required String imageUrl,
    required String savePath,
    required CancelToken cancelToken,
  }) async {
    try {
      await _api.download(
        imageUrl,
        savePath,
        cancelToken: cancelToken,
        options: Options(
          headers: {
            'Referer': 'https://picacomic.com',
          },
        ),
      );
    } on DioException catch (e) {
      if (e.type != DioExceptionType.cancel) {
        rethrow;
      }
    }
  }

  /// 清理资源
  void dispose() {
    _progressController.close();
    for (final token in _cancelTokens.values) {
      token.cancel('Repository disposed');
    }
  }
}

/// 下载进度事件
class DownloadProgressEvent {
  final String? comicId;
  final String? episodeId;
  final DownloadTaskStatus status;
  final int? progress;
  final int? downloadedPages;
  final int? totalPages;
  final String? error;
  final bool isCancelled;

  const DownloadProgressEvent({
    this.comicId,
    this.episodeId,
    required this.status,
    this.progress,
    this.downloadedPages,
    this.totalPages,
    this.error,
    this.isCancelled = false,
  });
}

/// Provider
final downloadRepositoryProvider = Provider<DownloadRepository>((ref) {
  final db = DatabaseHolder.instance;
  final repo = DownloadRepository(db);
  ref.onDispose(() => repo.dispose());
  return repo;
});

/// 下载列表Provider
final downloadListProvider = FutureProvider<List<DownloadTask>>((ref) async {
  final repo = ref.watch(downloadRepositoryProvider);
  return repo.getAllDownloads();
});

/// 下载列表状态Provider（用于实时更新）
final downloadStateProvider = StateNotifierProvider<DownloadStateNotifier, AsyncValue<List<DownloadTask>>>((ref) {
  final repo = ref.watch(downloadRepositoryProvider);
  return DownloadStateNotifier(repo);
});

class DownloadStateNotifier extends StateNotifier<AsyncValue<List<DownloadTask>>> {
  final DownloadRepository _repo;

  DownloadStateNotifier(this._repo) : super(const AsyncValue.loading()) {
    _loadDownloads();
    _listenToProgress();
  }

  Future<void> _loadDownloads() async {
    state = const AsyncValue.loading();
    try {
      final downloads = await _repo.getAllDownloads();
      state = AsyncValue.data(downloads);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  void _listenToProgress() {
    _repo.progressStream.listen((event) {
      _loadDownloads();
    });
  }

  Future<void> addDownload({
    required String comicId,
    required String title,
    required String coverUrl,
    String? author,
    List<String>? tags,
    required List<String> episodeIds,
    required List<String> episodeTitles,
  }) async {
    await _repo.addDownload(
      comicId: comicId,
      title: title,
      coverUrl: coverUrl,
      author: author,
      tags: tags,
      episodeIds: episodeIds,
      episodeTitles: episodeTitles,
    );
    await _loadDownloads();
  }

  Future<void> pauseDownload(String comicId) async {
    await _repo.pauseDownload(comicId);
    await _loadDownloads();
  }

  Future<void> resumeDownload(String comicId) async {
    await _repo.resumeDownload(comicId);
    await _loadDownloads();
  }

  Future<void> cancelDownload(String comicId) async {
    await _repo.cancelDownload(comicId);
    await _loadDownloads();
  }

  Future<void> pauseAll() async {
    await _repo.pauseAll();
    await _loadDownloads();
  }

  Future<void> resumeAll() async {
    await _repo.resumeAll();
    await _loadDownloads();
  }

  Future<void> deleteDownload(String comicId) async {
    await _repo.deleteDownload(comicId);
    await _loadDownloads();
  }

  Future<void> deleteDownloadWithFiles(String comicId) async {
    await _repo.deleteDownloadWithFiles(comicId);
    await _loadDownloads();
  }

  Future<void> refresh() async {
    await _loadDownloads();
  }
}

/// 选中下载的Provider
final selectedDownloadProvider = StateProvider<DownloadTask?>((ref) => null);
