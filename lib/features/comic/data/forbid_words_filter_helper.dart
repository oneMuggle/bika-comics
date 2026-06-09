import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'forbid_words_repository.dart';
import '../domain/comic_model.dart';

/// 屏蔽词过滤辅助
///
/// 让 list 屏幕无需关心 `ForbidWordsNotifier` 的细节：
/// ```dart
/// final filtered = ref.watch(filteredComicsProvider(rawComics));
/// ```
///
/// - 当 `forbidWordsProvider` 的 `selected` 为空时直接返回原列表（O(1)）；
/// - 否则按勾选维度（标题 / Tag / 分类）过滤。
/// - Riverpod 会在 `selected` 变化时自动重新执行。
final filteredComicsProvider =
    Provider.family<List<Comic>, List<Comic>>((ref, rawComics) {
  final state = ref.watch(forbidWordsProvider);
  return ForbidWordsFilter(state).apply(rawComics);
});
