// 第六十二批回归测试（续）：章节**顺序**与桌面端对齐 + 取消令牌透传
//
// 覆盖本批在接手在途 diff 时发现的 2 个真实缺陷：
//
//  D. 章节顺序与桌面端相反
//     桌面端 src/tools/book.py:183 用
//         index = epsCount - epsLimit * (page - 1) - i - 1
//     计算章节下标（index==0 是最老的一章），
//     src/view/info/book_eps_view.py:105 用
//         for index in range(0, info.epsCount)
//     **升序**渲染 -> 章节 1、2、3 ……
//     而 API 第 1 页返回的是**最新**的章节
//     （桌面端 src/view/info/book_info_view.py:445 的分页标签
//       "start = epsCount - i*epsLimit" 证实了这一点）。
//
//     在途 diff 把后续页简单追加到尾部 -> 整张表保持"最新在前"，与桌面端相反。
//     连带后果：移动端"开始阅读"在没有历史时取 initialEpisodeIndex = 0，
//     即列表第一项 = **最新的一章** —— 新漫画一点开始阅读直接跳到最后一章。
//     桌面端 src/view/info/book_info_view.py:594 StartRead() -> OpenReadIndex(0)
//     打开的是 epsId==0 = **第 1 章**。
//
//  E. 下载翻页丢失 cancelToken
//     在途 diff 把下载器从 `_api.get(..., cancelToken: cancelToken)` 改成
//     `_comicRepo.getAllEpisodeImages(...)`，**没有把 cancelToken 传下去**。
//     结果：用户点"暂停/取消下载"时，25 个分页组的 HTTP 请求仍会全部跑完。
//
// 本测试驱动**应用真正使用的仓库代码**（ComicRepository），
// 断言顺序与桌面端公式一致，并包含**对照组**证明断言有区分力。

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picacg_flutter/core/storage/secure_storage.dart';
import 'package:picacg_flutter/core/storage/settings_storage.dart';
import 'package:picacg_flutter/features/comic/data/comic_repository.dart';
import 'package:picacg_flutter/features/comic/domain/comic_model.dart';

/// 桌面端 src/tools/book.py:183 的下标公式（原文照抄）
int desktopIndex(int epsCount, int epsLimit, int page, int i) =>
    epsCount - epsLimit * (page - 1) - i - 1;

void main() {
  setUpAll(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    SecureStorageHolder.instance = SecureStorage(const FlutterSecureStorage());
  });

  group('第六十二批：章节顺序与桌面端对齐', () {
    late HttpServer server;
    late List<String> requestedPaths;
    late String baseUrl;

    // 一部 6 章的漫画，每页 2 章，共 3 页。
    // 章节 id 用 "eps_<order>"，order 从 6 递减到 1 —— 模拟 API 第 1 页返回最新章节。
    const epsCount = 6;
    const epsLimit = 2;
    const totalPages = 3;

    setUp(() async {
      requestedPaths = <String>[];

      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      baseUrl = 'http://127.0.0.1:${server.port}/';

      server.listen((HttpRequest request) async {
        final path = request.uri.path;
        final query = request.uri.query;
        requestedPaths.add(query.isEmpty ? path : '$path?$query');

        Map<String, dynamic> body;
        if (path.endsWith('/eps')) {
          final page =
              int.tryParse(request.uri.queryParameters['page'] ?? '1') ?? 1;
          // API 第 1 页 = 最新章节（order 从大到小）
          final all = List.generate(epsCount, (i) {
            final order = epsCount - i;
            return {
              '_id': 'eps_$order',
              'title': '第$order话',
              'order': order,
            };
          });
          final start = (page - 1) * epsLimit;
          final docs = start >= all.length
              ? <Map<String, dynamic>>[]
              : all.sublist(start, start + epsLimit);
          body = {
            'error': {'code': 0},
            'data': {
              'eps': {
                'docs': docs,
                'total': epsCount,
                'pages': totalPages,
                'limit': epsLimit,
                'page': page,
              }
            }
          };
        } else {
          body = {
            'error': {'code': 0},
            'data': <String, dynamic>{}
          };
        }

        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType.json
          ..write(jsonEncode(body));
        await request.response.close();
      });
    });

    tearDown(() async {
      await server.close(force: true);
      SettingsStorage.populateCache({});
    });

    void useLocalServer() {
      SettingsStorageHolder.instance =
          SettingsStorage(const FlutterSecureStorage());
      SettingsStorage.populateCache({'api_base_url': baseUrl});
    }

    test('章节顺序与桌面端下标公式一致（升序：第 1 章在前）', () async {
      useLocalServer();

      final repo = ComicRepository();
      final episodes = await repo.getAllEpisodes('comic-1');

      expect(episodes.length, epsCount, reason: '应把 3 页共 6 章全部收齐');

      // 桌面端渲染顺序 = 按下标升序 = eps_1, eps_2, ..., eps_6
      expect(
        episodes.map((e) => e.id).toList(),
        ['eps_1', 'eps_2', 'eps_3', 'eps_4', 'eps_5', 'eps_6'],
        reason: '桌面端 src/view/info/book_eps_view.py:105 升序渲染，'
            'index==0 是最老的一章；移动端必须一致',
      );

      // 每一章在升序列表里的位置，必须等于桌面端公式算出的下标
      // （桌面端把章节存进 epsDict[index] 再按下标升序渲染）
      for (var i = 0; i < episodes.length; i++) {
        expect(
          episodes[i].id,
          'eps_${i + 1}',
          reason: '第 $i 项必须对应桌面端下标 index=$i',
        );
      }
    });

    test('对照组：API 原始顺序是"最新在前"，与桌面端相反', () async {
      useLocalServer();

      // 直接打原始 API，拿到未经排序的顺序
      final dio = Dio();
      dio.options.baseUrl = baseUrl;
      final resp = await dio.get('/comics/comic-1/eps?page=1');
      final docs = (resp.data['data']['eps']['docs'] as List)
          .cast<Map<String, dynamic>>();

      expect(
        docs.map((d) => d['_id']).toList(),
        ['eps_6', 'eps_5'],
        reason: 'API 第 1 页返回最新章节 —— 这正是旧实现展示的顺序',
      );
      expect(
        docs.first['_id'],
        isNot('eps_1'),
        reason: '对照组必须与修复后的顺序不同，否则断言没有区分力',
      );
    });

    test('开始阅读入口：无历史时 index 0 是第 1 章（桌面端语义）', () async {
      useLocalServer();

      final repo = ComicRepository();
      final episodes = await repo.getAllEpisodes('comic-1');

      // comic_detail_screen.dart 的"开始阅读"在无历史时用 initialEpisodeIndex = 0
      const initialEpisodeIndex = 0;
      final started = episodes[initialEpisodeIndex];

      expect(
        started.id,
        'eps_1',
        reason: '桌面端 StartRead() -> OpenReadIndex(0) 打开的是 epsId==0 = 第 1 章；'
            '若列表是"最新在前"，这里会跳到第 6 章',
      );
      expect(started.order, 1, reason: '第 1 章的 order 应为 1');
    });

    test('sortEpisodesByDesktopOrder 与桌面端公式完全等价（多组参数）', () {
      // 直接用静态方法验证，不依赖网络
      const cases = [
        // (epsCount, epsLimit, pages)
        (389, 200, 2),
        (6, 2, 3),
        (100, 50, 2),
        (25, 25, 1),
        (201, 200, 2),
      ];

      for (final (epsCount, epsLimit, pages) in cases) {
        // 构造 API 原始顺序：第 1 页是最新的章节
        final raw = <Episode>[];
        for (var page = 1; page <= pages; page++) {
          for (var i = 0; i < epsLimit; i++) {
            if ((page - 1) * epsLimit + i >= epsCount) break;
            final index = desktopIndex(epsCount, epsLimit, page, i);
            raw.add(Episode(id: 'eps_${index + 1}', title: 't', order: index + 1));
          }
        }

        final sorted = ComicRepository.sortEpisodesByDesktopOrder(
          raw,
          epsCount: epsCount,
          epsLimit: epsLimit,
        );

        // 桌面端：按下标升序渲染
        final expected = <String>[];
        final epsDict = <int, String>{};
        for (var page = 1; page <= pages; page++) {
          for (var i = 0; i < epsLimit; i++) {
            final idx = desktopIndex(epsCount, epsLimit, page, i);
            if (idx >= 0 && idx < epsCount) epsDict[idx] = 'eps_${idx + 1}';
          }
        }
        final keys = epsDict.keys.toList()..sort();
        for (final k in keys) {
          expected.add(epsDict[k]!);
        }

        expect(
          sorted.map((e) => e.id).toList(),
          expected,
          reason: 'epsCount=$epsCount epsLimit=$epsLimit 时顺序必须与桌面端一致',
        );
      }
    });

    test('防御性回退：缺少 total/limit 时保持 API 原始顺序', () {
      final raw = [
        const Episode(id: 'b', title: 'b', order: 2),
        const Episode(id: 'a', title: 'a', order: 1),
      ];
      final sorted = ComicRepository.sortEpisodesByDesktopOrder(
        raw,
        epsCount: 0,
        epsLimit: 0,
      );
      expect(sorted.map((e) => e.id).toList(), ['b', 'a'],
          reason: '拿不到分页元信息时不应瞎猜顺序');
    });
  });

  group('第六十二批：下载翻页必须透传 cancelToken', () {
    late HttpServer server;
    late String baseUrl;
    late int requestCount;
    late Completer<void> secondRequestStarted;

    /// 第 2 个分页组是否挂起。
    ///
    /// 第六十二批修正：原先 mock **无条件**让第 2 组挂起 5 秒并返回空 body，
    /// 而两个测试共用同一个 mock：
    ///   * 取消测试需要"第 2 组在飞行中"——挂起是必需的；
    ///   * 正常翻页测试需要第 2 组**正常返回**。
    /// 无条件挂起导致正常翻页测试在第 2 组拿到空 docs（`data: {}` 没有
    /// `pages` 节点），`getAllEpisodeImages` 的 `if (next.urls.isEmpty) break;`
    /// 于是提前退出 —— 只收到第 1 组的 1 张图，断言 3 张失败。
    /// 缺陷在 mock 夹具，不在实现。
    late bool hangSecondPage;

    setUp(() async {
      requestCount = 0;
      hangSecondPage = false;
      secondRequestStarted = Completer<void>();
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      baseUrl = 'http://127.0.0.1:${server.port}/';

      server.listen((HttpRequest request) async {
        requestCount++;
        final page =
            int.tryParse(request.uri.queryParameters['page'] ?? '1') ?? 1;
        // 第 2 个分页组挂起，直到测试取消它 —— 这样"取消"一定发生在
        // 翻页请求**进行中**，而不是全部请求都已完成之后。
        if (page == 2 && hangSecondPage) {
          if (!secondRequestStarted.isCompleted) {
            secondRequestStarted.complete();
          }
          // 最多等 5 秒，避免测试挂死
          await Future<void>.delayed(const Duration(seconds: 5));
          try {
            request.response
              ..statusCode = 200
              ..headers.contentType = ContentType.json
              ..write(jsonEncode({'error': {'code': 0}, 'data': {}}));
            await request.response.close();
          } catch (_) {
            // 客户端已断开 —— 这正是取消的表现
          }
          return;
        }
        final body = {
          'error': {'code': 0},
          'data': {
            'pages': {
              'docs': [
                {
                  '_id': 'p$page',
                  'media': {
                    'fileServer': 'https://storage1.picacomic.com',
                    'path': 'tobeimg/page$page.jpg',
                  }
                }
              ],
              'total': 3,
              'pages': 3,
              'limit': 1,
              'page': page,
            }
          }
        };
        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType.json
          ..write(jsonEncode(body));
        await request.response.close();
      });
    });

    tearDown(() async {
      await server.close(force: true);
      SettingsStorage.populateCache({});
    });

    void useLocalServer() {
      SettingsStorageHolder.instance =
          SettingsStorage(const FlutterSecureStorage());
      SettingsStorage.populateCache({'api_base_url': baseUrl});
    }

    test('getAllEpisodeImages 接受 cancelToken 并在翻页时中断', () async {
      useLocalServer();
      hangSecondPage = true;

      final repo = ComicRepository();
      final token = CancelToken();

      final future = repo.getAllEpisodeImages(
        'comic-1',
        'eps-1',
        cancelToken: token,
      );

      // 等到第 2 个分页组的请求**真正发出**（它被服务端挂起）再取消
      await secondRequestStarted.future.timeout(
        const Duration(seconds: 10),
      );
      token.cancel('user cancelled');

      Object? caught;
      try {
        await future;
      } catch (e) {
        caught = e;
      }

      expect(caught, isNotNull, reason: '取消后应抛出 DioException 而不是继续翻页');
      expect(
        requestCount,
        lessThan(3),
        reason: '取消后不应再请求剩余分页组（总共 3 组）',
      );
    });

    test('不传 cancelToken 时正常翻完所有分页组', () async {
      useLocalServer();

      final repo = ComicRepository();
      final urls = await repo.getAllEpisodeImages('comic-1', 'eps-1');

      expect(urls.length, 3, reason: '3 个分页组各 1 张');
      expect(requestCount, 3);
    });
  });
}
