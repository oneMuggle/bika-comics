import 'package:flutter_test/flutter_test.dart';
import 'package:picacg_flutter/shared/constants/api_constants.dart';

void main() {
  group('P0/P1 关键端点与桌面端一致', () {
    test('登录使用 auth/sign-in', () {
      expect(ApiEndpoints.login, '/auth/sign-in');
    });

    test('收藏列表使用 users/favourite', () {
      expect(ApiEndpoints.myFavorites, '/users/favourite');
    });

    test('章节图片使用 order 路径并带页码', () {
      expect(
        ApiEndpoints.episodePages('comic-id', 'episode-id'),
        '/comics/comic-id/order/episode-id/pages?page=1',
      );
      expect(
        ApiEndpoints.episodePages('comic-id', 'episode-id', page: 2),
        '/comics/comic-id/order/episode-id/pages?page=2',
      );
    });

    test('分类漫画使用 comics c/s 查询参数并编码标题', () {
      expect(
        ApiEndpoints.categoryComics(
          category: 'Cosplay 中文',
          page: 2,
          sort: 'dd',
        ),
        '/comics?page=2&c=Cosplay+%E4%B8%AD%E6%96%87&s=dd',
      );
    });

    test('首页推荐和随机端点与桌面端一致', () {
      expect(ApiEndpoints.collections, '/collections');
      expect(ApiEndpoints.comicsRandom, '/comics/random');
    });
  });

  // 第五十九批：搜索关键词此前未经编码直接拼进 path，既能被 "&" 注入
  // 篡改语义，也会与签名对象不一致。现改为 Uri.encodeQueryComponent 编码。
  group('搜索端点编码（第五十九批）', () {
    test('中文关键词被正确编码', () {
      expect(
        ApiEndpoints.search(q: '女汉', page: 1),
        '/comics/search?q=%E5%A5%B3%E6%B1%89&page=1',
      );
    });

    test('含 "&" 的关键词不会注入额外查询参数', () {
      final url = ApiEndpoints.search(q: 'a&c=VC', page: 1);
      expect(url, '/comics/search?q=a%26c%3DVC&page=1');
      // 只有一个真正的查询参数分隔符（路径后的第一个 ?）
      expect('?'.allMatches(url).length, 1);
    });

    test('分类参数同样被编码', () {
      expect(
        ApiEndpoints.search(q: 'x', categories: 'Cosplay 中文', page: 2),
        '/comics/search?q=x&page=2&c=Cosplay+%E4%B8%AD%E6%96%87',
      );
    });

    test('分类为空时不会出现悬空的 &c=', () {
      expect(
        ApiEndpoints.search(q: 'x', categories: '', page: 1),
        '/comics/search?q=x&page=1',
      );
    });
  });
}
