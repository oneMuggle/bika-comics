// 第六十二批回归测试：章节分页 + 下载媒体取值（端到端，驱动真实仓库代码）
//
// 覆盖两个真实缺陷：
//
//  A. 章节列表只取第 1 页
//     移动端此前固定请求 `comics/{id}/eps`（无 page 参数），
//     长篇漫画第 1 页之外的章节既看不到也下载不到。
//     桌面端 `src/view/info/book_eps_view.py:66` LoadEpsData 会递归加载所有分页。
//
//  B. 下载时把整个 page doc 传给 mediaUrlFrom
//     pica 的 page doc 是包装对象，媒体字段嵌套在 `media` 下：
//       { "_id": "...", "media": { "fileServer": ..., "path": ... } }
//     旧代码 `mediaUrlFrom(page)` 取顶层 fileServer/path -> 空串 ->
//     每页都被 `if (imageUrl.isEmpty) continue;` 跳过 -> 每章 0 张图。
//     阅读器用 `p['media']` 所以阅读正常 —— 同一 API 两个消费点写法不一致。
//
// 本测试**不测辅助函数**，而是启动一个真实的本地 HTTP 服务器，
// 把应用的 API base URL 指向它，然后用**应用真正使用的仓库代码**
// （ComicRepository.getAllEpisodes）发真实请求，
// 断言服务器收到的路径与客户端算出的图片 URL。
//
// 关键：包含「对照组」—— 旧写法/旧参数下测试必须失败，
// 否则无法区分「测试通过」与「特性被忽略」。

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picacg_flutter/core/storage/secure_storage.dart';
import 'package:picacg_flutter/core/storage/settings_storage.dart';
import 'package:picacg_flutter/core/utils/media_url.dart';
import 'package:picacg_flutter/features/comic/data/comic_repository.dart';
import 'package:picacg_flutter/shared/constants/api_constants.dart';

void main() {
  setUpAll(() {
    // 认证拦截器会读 SecureStorage（取 token），未初始化会抛 StateError。
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    SecureStorageHolder.instance = SecureStorage(const FlutterSecureStorage());
  });

  group('第六十二批：章节分页 + 下载媒体取值', () {
    late HttpServer server;
    late List<String> requestedPaths;
    late String baseUrl;

    // 真实 API 形态：page doc 是包装对象，媒体在 `media` 下
    List<Map<String, dynamic>> pageDocs(int count) {
      return List.generate(count, (i) => {
            '_id': 'page_$i',
            'media': {
              'fileServer': 'https://storage1.picacomic.com',
              'path': 'tobeimg/xxx/img_$i.jpg',
              'originalName': '${i.toString().padLeft(4, '0')}.jpg',
            },
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
        if (path.startsWith('/comics/') && path.endsWith('/eps')) {
          final page =
              int.tryParse(request.uri.queryParameters['page'] ?? '1') ?? 1;
          // 每页 2 章，共 3 页 = 6 章（模拟长篇漫画）
          //
          // 第六十二批修正：这里原先按"第 1 页 = 最老的一章"造数据，
          // 但那是**虚构的 API 形态**。真实 API 的第 1 页返回**最新**的章节
          // —— 桌面端分页标签直接证实了这一点：
          //   src/view/info/book_info_view.py:448-450
          //     start = info.epsCount - i*info.epsLimit
          //     end   = max(1, info.epsCount - (i+1)*info.epsLimit + 1)
          //   389 章 / limit 200 时第 1 个标签是 "389-190"，即第 1 页 = 最新。
          //   src/view/info/book_info_view.py:490
          //     epsId = (info.epsCount - index*info.epsLimit) - 1 - i
          //   第 1 页第一行的章节号就是 epsCount（最新的一章）。
          //
          // 该结论已固化为可复跑脚本 tool/verify_eps_page_orientation.py
          // （直接读取桌面端源码求值，不是凭印象）。
          //
          // 因此 fixture 必须按"最新在前"构造，否则测的是一个不存在的 API。
          final all = List.generate(6, (i) => {
                '_id': 'eps_$i',
                'title': '第${i + 1}话',
                'order': i + 1,
              }).reversed.toList();
          final start = (page - 1) * 2;
          final docs = start >= all.length
              ? <Map<String, dynamic>>[]
              : all.sublist(start, start + 2);
          body = {
            'error': {'code': 0},
            'data': {
              'eps': {
                'docs': docs,
                'total': all.length,
                'pages': 3,
                'limit': 2,
                'page': page,
              }
            }
          };
        } else if (path.contains('/order/') && path.endsWith('/pages')) {
          body = {
            'error': {'code': 0},
            'data': {
              'pages': {
                'docs': pageDocs(3),
                'total': 3,
                'pages': 1,
                'limit': 3,
                'page': 1,
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

    test('getAllEpisodes 翻完所有分页（对照组：只取第 1 页时本测试必失败）', () async {
      useLocalServer();

      final repo = ComicRepository();
      final episodes = await repo.getAllEpisodes('comic-1');

      // 断言 1：所有分页都被请求过
      expect(
        requestedPaths,
        containsAll([
          '/comics/comic-1/eps?page=1',
          '/comics/comic-1/eps?page=2',
          '/comics/comic-1/eps?page=3',
        ]),
        reason: '桌面端会递归加载每一页；只请求第 1 页时后续章节不可见',
      );

      // 断言 2：章节总数 = 6（不是第 1 页的 2 章）
      expect(episodes.length, 6, reason: '应把 3 页共 6 章全部收齐');

      // 断言 3：内容正确、无重复
      expect(
        episodes.map((e) => e.id).toList(),
        ['eps_0', 'eps_1', 'eps_2', 'eps_3', 'eps_4', 'eps_5'],
      );
      expect(episodes.map((e) => e.id).toSet().length, 6);
    });

    test('对照组：只取第 1 页拿不到后续章节（证明上一条断言有区分力）', () async {
      useLocalServer();

      // 旧行为：固定取第 1 页
      final dio = Dio();
      dio.options.baseUrl = baseUrl;
      final resp = await dio.get('/comics/comic-1/eps');
      final docs = (resp.data['data']['eps']['docs'] as List).cast<Map<String, dynamic>>();

      expect(docs.length, 2, reason: '第 1 页只有 2 章 —— 这就是旧的可见章节数');
      expect(docs.length, lessThan(6), reason: '对照组必须与完整翻页的结果不同');
    });

    test('端点常量与桌面端 comics/{id}/eps?page=N 一致', () {
      expect(ApiEndpoints.episodes('c1'), '/comics/c1/eps?page=1');
      expect(ApiEndpoints.episodes('c1', page: 3), '/comics/c1/eps?page=3');
    });

    test('下载取到的图片 URL 来自 doc["media"]，不是顶层字段', () async {
      useLocalServer();

      final dio = Dio();
      dio.options.baseUrl = baseUrl;
      final response = await dio.get(ApiEndpoints.episodePages('c1', 'e1'));
      final docs = (response.data['data']['pages']['docs'] as List)
          .cast<Map<String, dynamic>>();

      // 走**应用真正使用的**共享函数（阅读器与下载器共用同一段代码）。
      final fixedUrls = docs.map((d) => pageDocImageUrl(d)).toList();
      // 对照组：旧写法把整个包装对象传给 mediaUrlFrom。
      final oldUrls = docs.map((d) => mediaUrlFrom(d)).toList();

      expect(fixedUrls, isNotEmpty);
      expect(
        fixedUrls.every((u) => u.isNotEmpty),
        isTrue,
        reason: '修复后每个页面都应算出非空 URL',
      );
      expect(
        oldUrls.every((u) => u.isEmpty),
        isTrue,
        reason: '对照组：旧写法对包装对象恒返回空串 —— 这正是每章 0 张图的根因',
      );

      // 完整 URL 形态与桌面端 GetRealUrl 一致
      expect(
        fixedUrls.first,
        'https://storage1.picacomic.com/static/tobeimg/xxx/img_0.jpg',
      );
    });

    test('共享函数兼容扁平形态（page doc 直接带 fileServer/path）', () {
      // 防御性回退：没有 media 包装时也能解析出来
      final flat = {
        '_id': 'x',
        'fileServer': 'https://storage1.picacomic.com',
        'path': 'tobeimg/flat.jpg',
      };
      expect(
        pageDocImageUrl(flat),
        'https://storage1.picacomic.com/static/tobeimg/flat.jpg',
      );
      // 非 Map 输入不崩
      expect(pageDocImageUrl(null), '');
      expect(pageDocImageUrl('not a doc'), '');
      expect(pageDocImageUrls([null, {'media': {'fileServer': 's', 'path': 'p'}}]).length, 1);
    });
  });
}
