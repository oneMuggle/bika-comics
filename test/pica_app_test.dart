import 'package:flutter_test/flutter_test.dart';
import 'package:picacg_flutter/features/pica_apps/domain/pica_app_model.dart';

void main() {
  group('PicaApp.fromJson', () {
    test('解析 _id 形式的标准响应', () {
      final app = PicaApp.fromJson(const {
        '_id': 'app_001',
        'title': '哔咔第三方客户端',
        'description': 'Android 第三方客户端',
        'url': 'https://example.com/download',
        'platform': 'android',
        // 真实 pica 媒体形态：fileServer 是主机，path 是相对路径。
        // 见 `/home/ubuntu/extract_db/book.db` 真实抓取数据：
        //   fileServer = 'https://storage1.picacomic.com'
        //   path       = 'tobeimg/.../xxx.jpg'   （相对，无前导 /）
        'icon': <String, String>{
          'fileServer': 'https://storage1.picacomic.com',
          'path': 'tobeimg/app/001.png',
        },
        'sort': 100,
      });
      expect(app.id, 'app_001');
      expect(app.title, '哔咔第三方客户端');
      expect(app.description, 'Android 第三方客户端');
      expect(app.url, 'https://example.com/download');
      expect(app.platform, 'android');
      // 桌面端 `ToolUtil.GetRealUrl` 的等价拼接：host + '/static/' + 相对路径。
      // 旧实现 `'$fileServer$path'` 会粘连成
      // 'https://storage1.picacomic.comtobeimg/app/001.png'（非法 URL）。
      expect(app.icon.url,
          'https://storage1.picacomic.com/static/tobeimg/app/001.png');
      expect(app.sort, 100);
      expect(app.isClickable, isTrue);
    });

    test('解析 id / name / downloadUrl 别名字段', () {
      final app = PicaApp.fromJson(const {
        'id': 'app_002',
        'name': 'iOS 桌面客户端',
        'link': 'https://apps.apple.com/app',
        'os': 'ios',
        'logo': 'https://cdn.example.com/002.png',
      });
      expect(app.id, 'app_002');
      expect(app.title, 'iOS 桌面客户端');
      expect(app.url, 'https://apps.apple.com/app');
      expect(app.platform, 'ios');
      expect(app.icon.url, 'https://cdn.example.com/002.png');
      expect(app.isClickable, isTrue);
    });

    test('缺字段时使用空字符串默认值', () {
      final app = PicaApp.fromJson(const {});
      expect(app.id, '');
      expect(app.title, '');
      expect(app.url, '');
      expect(app.platform, '');
      expect(app.icon.url, '');
      expect(app.description, '');
      expect(app.isClickable, isFalse);
    });

    test('icon 为字符串时直接当 path 使用', () {
      final app = PicaApp.fromJson(const {
        '_id': 'app_003',
        'title': 'Web App',
        'url': 'https://web.example.com',
        'icon': 'https://cdn.example.com/icon.png',
      });
      expect(app.icon.url, 'https://cdn.example.com/icon.png');
    });

    test('updated_at 解析 ISO8601 时间', () {
      final app = PicaApp.fromJson(const {
        '_id': 'app_004',
        'title': 'Time App',
        'url': 'https://e.example.com',
        'updated_at': '2026-05-20T12:34:56Z',
      });
      expect(app.updatedAt, isNotNull);
      expect(app.updatedAt!.year, 2026);
      expect(app.updatedAt!.month, 5);
      expect(app.updatedAt!.day, 20);
    });

    test('updated_at 解析失败时为 null(不抛异常)', () {
      final app = PicaApp.fromJson(const {
        '_id': 'app_005',
        'title': 'Bad Date',
        'url': 'https://e.example.com',
        'updated_at': 'not-a-date',
      });
      expect(app.updatedAt, isNull);
    });
  });
}
