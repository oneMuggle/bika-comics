import 'package:picacg_flutter/core/utils/media_url.dart';
import 'package:flutter_test/flutter_test.dart';

/// 媒体 URL 解析回归测试
///
/// ## 背景（真实缺陷）
///
/// 哔咔 API 返回的媒体对象是 `{fileServer, path}`：
///
/// ```json
/// { "fileServer": "https://storage1.picacomic.com",
///   "path": "tobeimg/xxx/rs:fill:300:400:0/g:sm/aHR0cHM6....jpg" }
/// ```
///
/// `path` 是**相对路径**。桌面端把两者分开存进 SQLite 两列
/// （`sql_server.py:267` 的 `path, fileServer`），用图时再拼：
/// `src/tools/tool.py:519` `ToolUtil.GetRealUrl(url, path)`
/// → `fileServer + "/static/" + path`
///
/// 移动端此前直接用 `path`（相对路径，图片加载失败），或拼
/// `'$fileServer$path'`（缺分隔符 → `https://storage1.picacomic.comtobeimg/...`，
/// 非法 URL）。两者都会让封面 / 阅读页图片全部加载不出来。
///
/// ## 本文件的向量来自真实数据
///
/// `/home/ubuntu/extract_db/book.db`（桌面端从真实 pica API 抓取的库）
/// 中的 `book.path` / `book.fileServer` 实际取值。
void main() {
  group('resolveMediaUrl — 桌面端 GetRealUrl 等价实现', () {
    test('真实 API 数据：fileServer + /static/ + 相对 path', () {
      const fileServer = 'https://storage1.picacomic.com';
      const path = 'tobeimg/gJ6Mi_2dCUJPGBu3_yWbPADhGqhMpZjVRuzaWnBeVVM/'
          'rs:fill:300:400:0/g:sm/aHR0cHM6Ly9zdG9yYWdlMS5waWNhY29taWMuY29t/'
          'L3N0YXRpYy81YzdjNWNlMC1mMjU5LTQxNTEtYTUzYS1hYjAyNTBiM2ZmM2IuanBn.jpg';

      final url = resolveMediaUrl(fileServer, path);

      expect(url.startsWith('https://storage1.picacomic.com/static/'), isTrue,
          reason: '必须带 /static/ 前缀，与桌面端 GetRealUrl 一致');
      expect(url.endsWith(path), isTrue, reason: '相对路径必须原样保留在末尾');
      expect(url.contains('storage1.picacomic.comtobeimg'), isFalse,
          reason: 'host 与 path 之间必须有一个 /（旧实现缺分隔符）');
      expect(Uri.tryParse(url)?.isAbsolute, isTrue, reason: '结果必须是合法绝对 URL');
    });

    test('结果 host 与 path 之间恰好一个分隔符', () {
      const fileServer = 'https://storage1.picacomic.com';
      const path = 'tobeimg/abc.jpg';

      final url = resolveMediaUrl(fileServer, path);

      expect(url, 'https://storage1.picacomic.com/static/tobeimg/abc.jpg');
      // host 部分之后紧跟 /static/
      final host = Uri.parse(url).host;
      expect(host, 'storage1.picacomic.com');
      expect(url.substring(url.indexOf(host) + host.length), '/static/tobeimg/abc.jpg');
    });

    test('fileServer 已以 static/ 结尾时不重复拼接（桌面端原规则）', () {
      expect(
        resolveMediaUrl('https://wikawika.xyz/static/', 'tobeimg/a.jpg'),
        'https://wikawika.xyz/static/tobeimg/a.jpg',
      );
    });

    test('path 为空时返回 fileServer', () {
      expect(
        resolveMediaUrl('https://storage1.picacomic.com', ''),
        'https://storage1.picacomic.com',
      );
    });

    test('fileServer 为空时返回 path', () {
      expect(resolveMediaUrl('', 'tobeimg/a.jpg'), 'tobeimg/a.jpg');
    });

    test('path 已是绝对 URL 时原样返回（防御性）', () {
      const absolute = 'https://storage1.picacomic.com/static/fc75975a.jpg';
      expect(
        resolveMediaUrl('https://storage1.picacomic.com', absolute),
        absolute,
      );
    });

    test('fileServer 带尾斜杠 / path 带首斜杠时不会产生双斜杠', () {
      expect(
        resolveMediaUrl('https://storage1.picacomic.com/', '/tobeimg/a.jpg'),
        'https://storage1.picacomic.com/static/tobeimg/a.jpg',
      );
    });
  });

  group('mediaUrlFrom — 从 API 媒体对象取 URL', () {
    test('标准 {fileServer, path} 形态', () {
      final url = mediaUrlFrom({
        'fileServer': 'https://storage1.picacomic.com',
        'path': 'tobeimg/a.jpg',
      });
      expect(url, 'https://storage1.picacomic.com/static/tobeimg/a.jpg');
    });

    test('null / 空对象返回空串', () {
      expect(mediaUrlFrom(null), '');
      expect(mediaUrlFrom(<String, dynamic>{}), '');
    });

    test('字符串形态原样返回', () {
      expect(mediaUrlFrom('https://x.com/a.jpg'), 'https://x.com/a.jpg');
    });

    test('只有 url 字段时原样返回', () {
      expect(
        mediaUrlFrom({'url': 'https://x.com/a.jpg'}),
        'https://x.com/a.jpg',
      );
    });
  });

  group('PicaMedia', () {
    test('fromJson + url 走同一套拼接规则', () {
      final media = PicaMedia.fromJson({
        'fileServer': 'https://storage1.picacomic.com',
        'path': 'tobeimg/a.jpg',
        'originalName': 'a.jpg',
      });
      expect(media.url, 'https://storage1.picacomic.com/static/tobeimg/a.jpg');
      expect(media.originalName, 'a.jpg');
      expect(media.isEmpty, isFalse);
    });

    test('空媒体对象', () {
      const media = PicaMedia.empty();
      expect(media.isEmpty, isTrue);
      expect(media.url, '');
    });
  });
}
