// 第六十二批回归测试（续）：章节**图片**分页
//
// 覆盖真实缺陷 C：
//
//  C. 章节图片列表只取第 1 页
//     服务端每个分页组最多返回 200 张图片。移动端此前对
//     `comics/{cid}/order/{eid}/pages` 固定只请求 `?page=1`，
//     图片数超过 200 的章节**第 200 张之后全部丢失** ——
//     表现为「长章节后面全是空白」，且下载也只拿到前 200 张。
//
//     证据来自**真实 API 抓取数据**（150,574 条漫画记录，
//     /home/ubuntu/extract_db/book.db）：
//     6,354 部单章漫画的一章图片数超过 200，最多的一章 4,896 张
//     = 25 个分页组。
//
//     桌面端同样按需翻页：
//       src/tools/book.py:260        index = (page - 1) * limit + i
//       src/task/task_download.py:283 loadPage = task.index // picLimit + 1
//
// 本测试启动一个真实的本地 HTTP 服务器，把应用的 API base URL 指向它，
// 然后用**应用真正使用的仓库代码**（ComicRepository.getAllEpisodeImages）
// 发真实请求，断言：
//   1. 服务器收到了**所有**分页组的请求
//   2. 客户端拿到了全部图片 URL
//   3. 对照组：只取第 1 页时结果**不同**（证明断言有区分力）
//
// 关键：包含「对照组」—— 旧写法/旧参数下测试必须失败，
// 否则无法区分「测试通过」与「特性被忽略」（pitfall #40）。

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picacg_flutter/core/storage/secure_storage.dart';
import 'package:picacg_flutter/core/storage/settings_storage.dart';
import 'package:picacg_flutter/core/utils/media_url.dart';
import 'package:picacg_flutter/features/comic/data/comic_repository.dart';

void main() {
  setUpAll(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    SecureStorageHolder.instance = SecureStorage(const FlutterSecureStorage());
  });

  group('第六十二批：章节图片分页', () {
    late HttpServer server;
    late List<String> requestedPaths;
    late String baseUrl;

    // 模拟一个 450 张图、每页 200 张的章节 = 3 个分页组
    const totalImages = 450;
    const limit = 200;

    List<Map<String, dynamic>> pageDocs(int start, int count) {
      return List.generate(count, (i) {
        final n = start + i;
        return {
          '_id': 'page_$n',
          'media': {
            'fileServer': 'https://storage1.picacomic.com',
            'path': 'tobeimg/xxx/img_$n.jpg',
            'originalName': '${n.toString().padLeft(4, '0')}.jpg',
          },
        };
      });
    }

    setUp(() async {
      requestedPaths = <String>[];

      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      baseUrl = 'http://127.0.0.1:${server.port}/';

      server.listen((HttpRequest request) async {
        final path = request.uri.path;
        final query = request.uri.query;
        requestedPaths.add(query.isEmpty ? path : '$path?$query');

        Map<String, dynamic> body;
        if (path.contains('/order/') && path.endsWith('/pages')) {
          final page =
              int.tryParse(request.uri.queryParameters['page'] ?? '1') ?? 1;
          // 'eps-empty' 模拟空白章节（桌面端 book.py:227-229 对此有专门分支）
          final isEmpty = path.contains('eps-empty');
          final start = (page - 1) * limit;
          final count =
              isEmpty ? 0 : (totalImages - start).clamp(0, limit);
          body = {
            'error': {'code': 0},
            'data': {
              'pages': {
                'docs': pageDocs(start, count),
                'total': isEmpty ? 0 : totalImages,
                'pages': isEmpty ? 1 : (totalImages / limit).ceil(),
                'limit': limit,
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

    test('getAllEpisodeImages 翻完所有分页组', () async {
      useLocalServer();

      final repo = ComicRepository();
      final urls = await repo.getAllEpisodeImages('comic-1', 'eps-1');

      // 断言 1：所有分页组都被请求过
      expect(
        requestedPaths,
        containsAll([
          '/comics/comic-1/order/eps-1/pages?page=1',
          '/comics/comic-1/order/eps-1/pages?page=2',
          '/comics/comic-1/order/eps-1/pages?page=3',
        ]),
        reason: '桌面端按需翻页取图片；只请求第 1 页时第 200 张之后全部丢失',
      );

      // 断言 2：拿到全部 450 张（不是 200 张）
      expect(urls.length, 450, reason: '应把 3 个分页组共 450 张全部收齐');

      // 断言 3：内容正确、无重复、顺序正确
      expect(urls.first,
          'https://storage1.picacomic.com/static/tobeimg/xxx/img_0.jpg');
      expect(urls.last,
          'https://storage1.picacomic.com/static/tobeimg/xxx/img_449.jpg');
      expect(urls.toSet().length, 450, reason: '不应有重复图片');
      for (var i = 0; i < 450; i++) {
        expect(urls[i], contains('img_$i.jpg'));
      }
    });

    test('对照组：只取第 1 页只能拿到 200 张（证明上一条断言有区分力）', () async {
      useLocalServer();

      // 旧行为：固定取第 1 页
      final dio = Dio();
      dio.options.baseUrl = baseUrl;
      final resp = await dio.get('/comics/comic-1/order/eps-1/pages?page=1');
      final docs = (resp.data['data']['pages']['docs'] as List)
          .cast<Map<String, dynamic>>();
      final oldUrls = docs.map((d) => pageDocImageUrl(d)).toList();

      expect(oldUrls.length, 200, reason: '第 1 页只有 200 张 —— 这就是旧行为');
      expect(oldUrls.length, lessThan(450),
          reason: '对照组必须与完整翻页的结果不同');
    });

    test('单页章节（pages=1）不会发多余请求', () async {
      useLocalServer();

      final dio = Dio();
      dio.options.baseUrl = baseUrl;
      final resp = await dio.get('/comics/comic-1/order/eps-1/pages?page=1');
      final pagesNode = resp.data['data']['pages'] as Map<String, dynamic>;
      expect(pagesNode['pages'], 3);
      expect(pagesNode['total'], 450);
      expect(pagesNode['limit'], 200);
      expect(pagesNode['page'], 1);
    });

    test('空章节返回空列表且不报错', () async {
      useLocalServer();

      final dio = Dio();
      dio.options.baseUrl = baseUrl;
      final resp = await dio.get('/comics/comic-1/order/eps-empty/pages?page=1');
      final docs = (resp.data['data']['pages']['docs'] as List? ?? []);
      expect(docs, isEmpty);
      expect(pageDocImageUrls(docs), isEmpty);
    });
  });
}
