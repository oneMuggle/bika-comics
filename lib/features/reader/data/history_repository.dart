import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../../../core/db/database.dart';

/// 阅读历史仓库
///
/// 第十五批新增：封装 `AppDatabase.upsertHistory` 调用。
/// 阅读器在翻页时调用 [saveReadingPosition]；详情页"继续阅读"调用
/// [getContinueReadingForComic] 决定初始页码；历史列表点击时调用
/// [getContinueReadingForRemoteComicId] 通过远程 ID 查找历史。
class HistoryRepository {
  HistoryRepository._();

  static HistoryRepository? _instance;
  static HistoryRepository get instance =>
      _instance ??= HistoryRepository._();

  /// 第十五批：单元测试入口 — 清空 instance 缓存。
  /// 下次访问 `.instance` 时会用新的 DatabaseHolder.instance 重建。
  /// 仅供 `test/` 目录调用。
  @visibleForTesting
  static void resetForTest() {
    _instance = null;
  }

  final AppDatabase _db = DatabaseHolder.instance;

  /// 通过远程 comicId 查找历史记录（先找本地 comic，再查 history）
  /// 返回 (history, episodeIndex, lastPage) 或 null
  Future<ContinueReadingInfo?> getContinueReadingForRemoteComicId(
    String remoteComicId,
  ) async {
    final localComic = await _db.getComicByRemoteId(remoteComicId);
    if (localComic == null) return null;
    return _buildContinueInfo(localComic);
  }

  /// 通过本地 comicId 查找历史记录
  Future<ContinueReadingInfo?> getContinueReadingForLocalComicId(
    int localComicId,
  ) async {
    final localComic = await _db.getComicById(localComicId);
    if (localComic == null) return null;
    return _buildContinueInfo(localComic);
  }

  Future<ContinueReadingInfo?> _buildContinueInfo(Comic localComic) async {
    final history = await _db.getHistoryForComic(localComic.id);
    if (history == null) return null;

    // 把历史中的 episodeId（本地 PK）转换为远程 episode id
    final episode = await _db
        .getEpisodesForComic(localComic.id)
        .then((eps) => eps.where((e) => e.id == history.episodeId).firstOrNull);
    if (episode == null) return null;

    return ContinueReadingInfo(
      remoteComicId: localComic.comicId,
      remoteEpisodeId: episode.episodeId,
      lastPage: history.lastPage,
      lastReadAt: history.lastReadAt,
    );
  }

  /// 保存阅读位置
  ///
  /// 阅读器在每次翻页（节流 500ms 内一次）调用本方法。
  /// 自动 upsert 本地 comic + episode（如果不存在），然后写入历史。
  Future<void> saveReadingPosition({
    required String remoteComicId,
    required String remoteEpisodeId,
    required int page,
  }) async {
    try {
      // 1. 确保本地 comic 行存在
      var localComic = await _db.getComicByRemoteId(remoteComicId);
      if (localComic == null) {
        // 创建占位 comic 行（标题/封面为空也没关系 — 下次打开详情页会被覆盖）
        final insertedId = await _db.insertComic(
          ComicsCompanion.insert(
            comicId: remoteComicId,
            title: '',
            coverUrl: '',
          ),
        );
        localComic = await _db.getComicById(insertedId);
      }
      if (localComic == null) return;

      // 2. 确保本地 episode 行存在
      var localEpisode = await _db.getEpisodeByRemoteId(remoteEpisodeId);
      if (localEpisode == null) {
        final order = await _db
            .getEpisodesForComic(localComic.id)
            .then((eps) => eps.length);
        await _db.insertEpisode(
          EpisodesCompanion.insert(
            episodeId: remoteEpisodeId,
            comicId: localComic.id,
            title: '',
            order: order,
          ),
        );
        localEpisode = await _db.getEpisodeByRemoteId(remoteEpisodeId);
      }
      if (localEpisode == null) return;

      // 3. upsert 历史
      await _db.upsertHistory(
        HistoryCompanion(
          comicId: Value(localComic.id),
          episodeId: Value(localEpisode.id),
          lastPage: Value(page),
          lastReadAt: Value(DateTime.now()),
        ),
      );
    } catch (e) {
      // 不阻塞阅读流程；记录到 debug log
      if (kDebugMode) {
        debugPrint('HistoryRepository.saveReadingPosition failed: $e');
      }
    }
  }
}

/// 继续阅读信息
@immutable
class ContinueReadingInfo {
  final String remoteComicId;
  final String remoteEpisodeId;
  final int lastPage;
  final DateTime lastReadAt;

  const ContinueReadingInfo({
    required this.remoteComicId,
    required this.remoteEpisodeId,
    required this.lastPage,
    required this.lastReadAt,
  });
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}