import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

/// 漫画表
class Comics extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get comicId => text().unique()(); // 远程ID
  TextColumn get title => text()();
  TextColumn get author => text().nullable()();
  TextColumn get coverUrl => text()();
  TextColumn get description => text().nullable()();
  IntColumn get episodeCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  BoolColumn get isFollowed => boolean().withDefault(const Constant(false))();
}

/// 章节表
class Episodes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get episodeId => text().unique()(); // 远程ID
  IntColumn get comicId => integer().references(Comics, #id)();
  TextColumn get title => text()();
  IntColumn get order => integer()(); // 章节顺序
  DateTimeColumn get publishedAt => dateTime().nullable()();
}

/// 阅读历史表
class History extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get comicId => integer().references(Comics, #id)();
  IntColumn get episodeId => integer().references(Episodes, #id)();
  IntColumn get lastPage => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastReadAt => dateTime()();
}

/// 下载任务表 - 支持整本漫画下载
class Downloads extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get comicId => text()(); // 远程漫画ID
  TextColumn get title => text()(); // 漫画标题
  TextColumn get coverUrl => text()(); // 封面URL
  TextColumn get author => text().nullable()(); // 作者
  TextColumn get tags => text().nullable()(); // 标签，逗号分隔
  TextColumn get downloadedEpisodeIds => text()(); // 已下载的章节ID列表，JSON格式
  TextColumn get pendingEpisodeIds => text()(); // 待下载的章节ID列表，JSON格式
  TextColumn get status => text()(); // pending, downloading, paused, completed, failed
  IntColumn get totalEpisodes => integer().withDefault(const Constant(0))(); // 总章节数
  IntColumn get completedEpisodes => integer().withDefault(const Constant(0))(); // 已完成章节数
  IntColumn get currentEpisodeIndex => integer().withDefault(const Constant(0))(); // 当前下载的章节索引
  TextColumn get currentEpisodeId => text().nullable()(); // 当前下载的章节ID
  TextColumn get localPath => text().nullable()(); // 本地保存路径
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
}

/// 下载进度表 - 跟踪每个章节的下载进度
class DownloadProgress extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get downloadId => integer().references(Downloads, #id)();
  TextColumn get episodeId => text()(); // 远程章节ID
  TextColumn get episodeTitle => text()(); // 章节标题
  IntColumn get totalPages => integer().withDefault(const Constant(0))(); // 总页数
  IntColumn get downloadedPages => integer().withDefault(const Constant(0))(); // 已下载页数
  TextColumn get status => text()(); // pending, downloading, completed, failed
  IntColumn get progress => integer().withDefault(const Constant(0))(); // 进度 0-100
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
}

/// 搜索历史表
class SearchHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get keyword => text()();
  DateTimeColumn get searchedAt => dateTime()();
}

@DriftDatabase(tables: [Comics, Episodes, History, Downloads, DownloadProgress, SearchHistory])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // 迁移逻辑
      },
    );
  }

  Future<void> initialize() async {
    // 数据库初始化时可以在这里做迁移
  }

  // ================== Comics ==================

  Future<List<Comic>> getAllComics() => select(comics).get();

  Future<Comic?> getComicByRemoteId(String remoteId) =>
      (select(comics)..where((c) => c.comicId.equals(remoteId)))
          .getSingleOrNull();

  Future<Comic?> getComicById(int id) =>
      (select(comics)..where((c) => c.id.equals(id)))
          .getSingleOrNull();

  Future<int> insertComic(ComicsCompanion comic) =>
      into(comics).insert(comic, mode: InsertMode.insertOrReplace);

  Future<void> updateComic(Comic comic) => update(comics).replace(comic);

  Future<int> deleteComic(int id) =>
      (delete(comics)..where((c) => c.id.equals(id))).go();

  // ================== Episodes ==================

  Future<List<Episode>> getEpisodesForComic(int comicId) =>
      (select(episodes)
            ..where((e) => e.comicId.equals(comicId))
            ..orderBy([(e) => OrderingTerm.asc(e.order)]))
          .get();

  Future<Episode?> getEpisodeByRemoteId(String remoteId) =>
      (select(episodes)..where((e) => e.episodeId.equals(remoteId)))
          .getSingleOrNull();

  Future<int> insertEpisode(EpisodesCompanion episode) =>
      into(episodes).insert(episode, mode: InsertMode.insertOrReplace);

  // ================== History ==================

  Future<List<HistoryData>> getRecentHistory({int limit = 50}) =>
      (select(history)
            ..orderBy([(h) => OrderingTerm.desc(h.lastReadAt)])
            ..limit(limit))
          .get();

  Future<HistoryData?> getHistoryForComic(int comicId) =>
      (select(history)..where((h) => h.comicId.equals(comicId)))
          .getSingleOrNull();

  Future<int> upsertHistory(HistoryCompanion entry) => into(history).insert(
        entry,
        mode: InsertMode.insertOrReplace,
      );

  Future<int> deleteHistory(int id) =>
      (delete(history)..where((h) => h.id.equals(id))).go();

  Future<void> clearAllHistory() => delete(history).go();

  // ================== Downloads ==================

  Future<List<Download>> getAllDownloads() => select(downloads).get();

  Future<List<Download>> getPendingDownloads() =>
      (select(downloads)..where((d) => d.status.equals('pending'))).get();

  Future<List<Download>> getActiveDownloads() =>
      (select(downloads)..where((d) => d.status.equals('downloading'))).get();

  Future<List<Download>> getPausedDownloads() =>
      (select(downloads)..where((d) => d.status.equals('paused'))).get();

  Future<Download?> getDownloadByComicId(String comicId) =>
      (select(downloads)..where((d) => d.comicId.equals(comicId)))
          .getSingleOrNull();

  Future<int> insertDownload(DownloadsCompanion download) =>
      into(downloads).insert(download);

  Future<void> updateDownload(Download download) =>
      update(downloads).replace(download);

  Future<void> updateDownloadStatus(String comicId, String status, {int? completedEpisodes, String? currentEpisodeId, String? localPath}) async {
    final download = await getDownloadByComicId(comicId);
    if (download == null) return;
    
    await (update(downloads)..where((d) => d.comicId.equals(comicId))).write(
      DownloadsCompanion(
        status: Value(status),
        completedEpisodes: completedEpisodes != null ? Value(completedEpisodes) : Value(download.completedEpisodes),
        currentEpisodeId: currentEpisodeId != null ? Value(currentEpisodeId) : Value(download.currentEpisodeId),
        localPath: localPath != null ? Value(localPath) : Value(download.localPath),
        updatedAt: Value(DateTime.now()),
        completedAt: status == 'completed' ? Value(DateTime.now()) : const Value.absent(),
      ),
    );
  }

  Future<int> deleteDownloadByComicId(String comicId) =>
      (delete(downloads)..where((d) => d.comicId.equals(comicId))).go();

  Future<void> deleteAllDownloads() => delete(downloads).go();

  // ================== DownloadProgress ==================

  Future<List<DownloadProgressData>> getProgressForDownload(int downloadId) =>
      (select(downloadProgress)..where((p) => p.downloadId.equals(downloadId))).get();

  Future<DownloadProgressData?> getProgressForEpisode(int downloadId, String episodeId) =>
      (select(downloadProgress)
            ..where((p) => p.downloadId.equals(downloadId) & p.episodeId.equals(episodeId)))
          .getSingleOrNull();

  Future<int> insertDownloadProgress(DownloadProgressCompanion progress) =>
      into(downloadProgress).insert(progress, mode: InsertMode.insertOrReplace);

  Future<void> updateDownloadProgress(int downloadId, String episodeId, {int? downloadedPages, String? status, int? progress}) async {
    final existing = await getProgressForEpisode(downloadId, episodeId);
    if (existing == null) return;

    await (update(downloadProgress)
          ..where((p) => p.downloadId.equals(downloadId) & p.episodeId.equals(episodeId)))
        .write(
      DownloadProgressCompanion(
        downloadedPages: downloadedPages != null ? Value(downloadedPages) : Value(existing.downloadedPages),
        status: status != null ? Value(status) : Value(existing.status),
        progress: progress != null ? Value(progress) : Value(existing.progress),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> deleteProgressForDownload(int downloadId) =>
      (delete(downloadProgress)..where((p) => p.downloadId.equals(downloadId))).go();

  // ================== Search History ==================

  Future<List<SearchHistoryData>> getSearchHistory({int limit = 20}) =>
      (select(searchHistory)
            ..orderBy([(s) => OrderingTerm.desc(s.searchedAt)])
            ..limit(limit))
          .get();

  Future<int> insertSearchHistory(String keyword) => into(searchHistory).insert(
        SearchHistoryCompanion(
          keyword: Value(keyword),
          searchedAt: Value(DateTime.now()),
        ),
      );

  Future<void> clearSearchHistory() => delete(searchHistory).go();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'picacg.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

/// 数据库全局访问器
class DatabaseHolder {
  static AppDatabase? _instance;

  static AppDatabase get instance {
    if (_instance == null) {
      throw StateError('Database not initialized. Call main() first.');
    }
    return _instance!;
  }

  static set instance(AppDatabase value) {
    _instance = value;
  }
}
