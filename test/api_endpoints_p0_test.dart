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
}
