import 'package:picacg_flutter/features/comic/domain/comic_model.dart';
import 'package:picacg_flutter/features/comic/domain/comment_model.dart';
import 'package:picacg_flutter/features/comic/domain/knight_model.dart';
import 'package:picacg_flutter/features/game/domain/game_model.dart';
import 'package:picacg_flutter/features/pica_apps/domain/pica_app_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// 模型层媒体 URL 回归测试
///
/// **测试消费者，而不是只测工具函数**（见 skill pitfall #40）：
/// 这里的每个断言都直接调用 App 真正使用的 `fromJson`，
/// 断言产出的 URL 能被 `Uri.parse` 解析、且指向真实可达的 host。
///
/// 真实数据取自 `/home/ubuntu/extract_db/book.db`：
/// ```
/// path       = 'tobeimg/gJ6Mi_.../aHR0cHM6Ly9zdG9yYWdlMS5waWNhY29taWMuY29tL3N0YXRpYy81YzdjNWNlMC0....jpg'
/// fileServer = 'https://storage1.picacomic.com'
/// ```
const kRealFileServer = 'https://storage1.picacomic.com';
const kRealPath =
    'tobeimg/gJ6Mi_2dCUJPGBu3_yWbPADhGqhMpZjVRuzaWnBeVVM/rs:fill:300:400:0/g:sm/'
    'aHR0cHM6Ly9zdG9yYWdlMS5waWNhY29taWMuY29tL3N0YXRpYy81YzdjNWNlMC1mMjU5LTQxNTEtYTUzYS1hYjAyNTBiM2ZmM2IuanBn.jpg';

/// 断言这是一个**可用于图片加载**的绝对 URL
void expectLoadableUrl(String url, {required String what}) {
  expect(url, isNotEmpty, reason: '$what 不应为空');
  final uri = Uri.tryParse(url);
  expect(uri, isNotNull, reason: '$what 不是合法 URI: $url');
  expect(uri!.isAbsolute, isTrue, reason: '$what 必须是绝对 URL: $url');
  expect(uri.host, 'storage1.picacomic.com', reason: '$what 的 host 不对: $url');
  expect(uri.path, startsWith('/static/'), reason: '$what 缺少 /static/ 前缀: $url');
  // host 与 path 之间不能出现 "comtobeimg" 这类粘连
  expect(url.contains('picacomic.comtobeimg'), isFalse,
      reason: '$what host 与 path 粘连（缺分隔符）: $url');
}

void main() {
  group('Comic.coverUrl — 封面（首页 / 分类 / 收藏列表）', () {
    test('真实 API 形态产出可加载 URL', () {
      final comic = Comic.fromJson(const {
        '_id': 'c1',
        'title': '测试漫画',
        'cover': {'fileServer': kRealFileServer, 'path': kRealPath},
      });
      expectLoadableUrl(comic.coverUrl, what: 'coverUrl');
    });

    test('cover 为字符串时原样使用', () {
      final comic = Comic.fromJson(const {
        '_id': 'c1',
        'cover': 'https://storage1.picacomic.com/static/x.jpg',
      });
      expect(comic.coverUrl, 'https://storage1.picacomic.com/static/x.jpg');
    });

    test('cover 缺失时为空串', () {
      final comic = Comic.fromJson(const {'_id': 'c1'});
      expect(comic.coverUrl, '');
    });
  });

  group('Comment.userAvatar — 评论头像', () {
    test('真实 API 形态产出可加载 URL', () {
      final comment = Comment.fromJson({
        '_id': 'x1',
        'content': 'hello',
        'user': {
          '_id': 'u1',
          'name': 'someone',
          'avatar': {'fileServer': kRealFileServer, 'path': kRealPath},
        },
      });
      expectLoadableUrl(comment.userAvatar, what: 'userAvatar');
    });
  });

  group('KnightAvatar.url — 骑士榜头像', () {
    test('真实 API 形态产出可加载 URL', () {
      final avatar = KnightAvatar.fromJson(const {
        'fileServer': kRealFileServer,
        'path': kRealPath,
      });
      expectLoadableUrl(avatar.url, what: 'knight avatar');
    });
  });

  group('GameIcon.url — 游戏图标', () {
    test('真实 API 形态产出可加载 URL', () {
      final icon = GameIcon.fromJson(const {
        'fileServer': kRealFileServer,
        'path': kRealPath,
      });
      expectLoadableUrl(icon.url, what: 'game icon');
    });
  });

  group('PicaAppIcon.url — Pica Apps 图标', () {
    test('真实 API 形态产出可加载 URL', () {
      final icon = PicaAppIcon.fromJson(const {
        'fileServer': kRealFileServer,
        'path': kRealPath,
      });
      expectLoadableUrl(icon.url, what: 'pica app icon');
    });
  });

  group('媒体对象只有 url 字段时的回退', () {
    test('KnightAvatar 兼容 {url} 形态', () {
      final avatar = KnightAvatar.fromJson(const {
        'url': 'https://storage1.picacomic.com/static/x.jpg',
      });
      expect(avatar.url, 'https://storage1.picacomic.com/static/x.jpg');
    });

    test('GameIcon 兼容 {url} 形态', () {
      final icon = GameIcon.fromJson(const {
        'url': 'https://storage1.picacomic.com/static/x.jpg',
      });
      expect(icon.url, 'https://storage1.picacomic.com/static/x.jpg');
    });

    test('PicaAppIcon 兼容 {url} 形态', () {
      final icon = PicaAppIcon.fromJson(const {
        'url': 'https://storage1.picacomic.com/static/x.jpg',
      });
      expect(icon.url, 'https://storage1.picacomic.com/static/x.jpg');
    });
  });
}
