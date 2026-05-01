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

/// 下载任务表
class Downloads extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get comicId => integer().references(Comics, #id)();
  IntColumn get episodeId => integer().references(Episodes, #id)();
  TextColumn get status => text()(); // pending, downloading, completed, failed
  IntColumn get progress => integer().withDefault(const Constant(0))(); // 0-100
  TextColumn get localPath => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
}

/// 搜索历史表
class SearchHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get keyword => text()();
  DateTimeColumn get searchedAt => dateTime()();
}

@DriftDatabase(tables: [Comics, Episodes, History, Downloads, SearchHistory])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  Future<void> initialize() async {
    // 数据库初始化时可以在这里做迁移
  }

  // ================== Comics ==================

  Future<List<Comic>> getAllComics() => select(comics).get();

  Future<Comic?> getComicByRemoteId(String remoteId) =>
      (select(comics)..where((c) => c.comicId.equals(remoteId)))
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

  Future<int> insertDownload(DownloadsCompanion download) =>
      into(downloads).insert(download);

  Future<void> updateDownloadStatus(int id, String status, {int? progress, String? localPath}) =>
      (update(downloads)..where((d) => d.id.equals(id))).write(
        DownloadsCompanion(
          status: Value(status),
          progress: progress != null ? Value(progress) : const Value.absent(),
          localPath: localPath != null ? Value(localPath) : const Value.absent(),
          completedAt: status == 'completed' ? Value(DateTime.now()) : const Value.absent(),
        ),
      );

  Future<int> deleteDownload(int id) =>
      (delete(downloads)..where((d) => d.id.equals(id))).go();

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
