import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picacg_flutter/features/comic/presentation/my_favourites_screen.dart';

void main() {
  test('收藏排序 API 值与桌面端一致', () {
    expect(FavouritesSort.newestFirst.apiValue, 'dd');
    expect(FavouritesSort.newestFirst.label, '新到旧');
    expect(FavouritesSort.oldestFirst.apiValue, 'da');
    expect(FavouritesSort.oldestFirst.label, '旧到新');
  });

  test('收藏排序默认使用新到旧', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      container.read(favouritesSortProvider),
      FavouritesSort.newestFirst,
    );
  });
}
