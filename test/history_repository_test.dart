// 第十五批：HistoryRepository 单元测试
//
// 验证：
// 1. 首次保存 → 新建本地 comic + episode + history
// 2. 再次保存同 (comic, episode) → 复用本地 id，仅更新 history 页码
// 3. 切换 episode → 新建 episode 行，history 指向新 episode
// 4. getContinueReadingForRemoteComicId 正确返回最近一次保存的位置

import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picacg_flutter/core/db/database.dart';
import 'package:picacg_flutter/features/reader/data/history_repository.dart';
import 'package:sqlite3/open.dart';

void main() {
  late AppDatabase db;
  late HistoryRepository repo;

  setUpAll(() {
    // 在 CI / Linux 桌面上 sqlite3 默认会去找 `libsqlite3.so`，
    // 但很多发行版只提供带版本号的 `libsqlite3.so.0`。
    // 这里在测试启动时一次性把 sqlite3 的动态库加载器重定向到带版本号的 .so。
    if (Platform.isLinux) {
      open.overrideFor(OperatingSystem.linux,
          () => DynamicLibrary.open('libsqlite3.so.0'));
    }
  });

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    // 把 DatabaseHolder 替换为 in-memory 数据库
    DatabaseHolder.overrideForTest(db);
    repo = HistoryRepository.instance;
  });

  tearDown(() async {
    await db.close();
    // 第十五批：清空 HistoryRepository 缓存的下一次测试 setUp 会重建。
    HistoryRepository.resetForTest();
  });

  test('首次保存创建本地 comic + episode + history', () async {
    await repo.saveReadingPosition(
      remoteComicId: 'comic-1',
      remoteEpisodeId: 'ep-1',
      page: 5,
    );

    final info = await repo.getContinueReadingForRemoteComicId('comic-1');
    expect(info, isNotNull);
    expect(info!.remoteComicId, 'comic-1');
    expect(info.remoteEpisodeId, 'ep-1');
    expect(info.lastPage, 5);
  });

  test('同 comic+episode 二次保存更新页码', () async {
    await repo.saveReadingPosition(
      remoteComicId: 'comic-1',
      remoteEpisodeId: 'ep-1',
      page: 5,
    );
    await repo.saveReadingPosition(
      remoteComicId: 'comic-1',
      remoteEpisodeId: 'ep-1',
      page: 12,
    );

    final info = await repo.getContinueReadingForRemoteComicId('comic-1');
    expect(info, isNotNull);
    expect(info!.lastPage, 12);

    // 应该只有一个本地 episode 行
    final localComic = await db.getComicByRemoteId('comic-1');
    expect(localComic, isNotNull);
    final eps = await db.getEpisodesForComic(localComic!.id);
    expect(eps.length, 1);
    expect(eps.first.episodeId, 'ep-1');
  });

  test('切换 episode 新建 episode 行', () async {
    await repo.saveReadingPosition(
      remoteComicId: 'comic-1',
      remoteEpisodeId: 'ep-1',
      page: 5,
    );
    await repo.saveReadingPosition(
      remoteComicId: 'comic-1',
      remoteEpisodeId: 'ep-2',
      page: 0,
    );

    final info = await repo.getContinueReadingForRemoteComicId('comic-1');
    expect(info, isNotNull);
    expect(info!.remoteEpisodeId, 'ep-2');
    expect(info.lastPage, 0);
  });

  test('不存在的漫画返回 null', () async {
    final info = await repo.getContinueReadingForRemoteComicId('unknown');
    expect(info, isNull);
  });
}