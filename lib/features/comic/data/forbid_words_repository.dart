import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/settings_storage.dart';
import '../domain/comic_model.dart';

/// 搜索屏蔽词仓库
///
/// 对应桌面端 `view/tool/forbid_words_view.py` + `Setting.ForbidWords` 等
/// - 桌面端逻辑：从所有分类 (`CateGoryMgr().allCategorise`) + 自定义 (`Setting.AddForbidWords`) 列表中
///   选择需要屏蔽的项，存到 `Setting.ForbidWords`。运行时按勾选的状态过滤漫画：
///     - 标题命中 -> 隐藏 (IsForbidTitle)
///     - Tag 命中 -> 隐藏 (IsForbidTag)
///     - 分类命中 -> 隐藏 (IsForbidCategory)
class ForbidWordsState {
  final List<String> customWords;
  final List<String> selected;
  final bool forbidTitle;
  final bool forbidTag;
  final bool forbidCategory;

  const ForbidWordsState({
    this.customWords = const [],
    this.selected = const [],
    this.forbidTitle = true,
    this.forbidTag = false,
    this.forbidCategory = false,
  });

  ForbidWordsState copyWith({
    List<String>? customWords,
    List<String>? selected,
    bool? forbidTitle,
    bool? forbidTag,
    bool? forbidCategory,
  }) {
    return ForbidWordsState(
      customWords: customWords ?? this.customWords,
      selected: selected ?? this.selected,
      forbidTitle: forbidTitle ?? this.forbidTitle,
      forbidTag: forbidTag ?? this.forbidTag,
      forbidCategory: forbidCategory ?? this.forbidCategory,
    );
  }
}

class ForbidWordsNotifier extends StateNotifier<ForbidWordsState> {
  final SettingsStorage _storage;
  ForbidWordsNotifier(this._storage) : super(const ForbidWordsState()) {
    _load();
  }

  Future<void> _load() async {
    final custom = await _storage.getForbidWords();
    final selected = await _storage.getForbidWords();
    final forbidTitle = await _storage.getIsForbidTitle();
    final forbidTag = await _storage.getIsForbidTag();
    final forbidCategory = await _storage.getIsForbidCategory();
    state = ForbidWordsState(
      customWords: custom,
      selected: selected,
      forbidTitle: forbidTitle,
      forbidTag: forbidTag,
      forbidCategory: forbidCategory,
    );
  }

  Future<void> setSelected(List<String> words) async {
    state = state.copyWith(selected: words);
    await _storage.setForbidWords(words);
  }

  Future<void> addWord(String word) async {
    final normalized = word.trim();
    if (normalized.isEmpty) return;
    if (state.customWords.contains(normalized)) return;
    final newCustom = [...state.customWords, normalized];
    final newSelected = [...state.selected, normalized];
    state = state.copyWith(customWords: newCustom, selected: newSelected);
    await _storage.setForbidWords(newSelected);
  }

  Future<void> removeWord(String word) async {
    final newCustom = state.customWords.where((w) => w != word).toList();
    final newSelected = state.selected.where((w) => w != word).toList();
    state = state.copyWith(customWords: newCustom, selected: newSelected);
    await _storage.setForbidWords(newSelected);
  }

  Future<void> setForbidTitle(bool v) async {
    state = state.copyWith(forbidTitle: v);
    await _storage.setIsForbidTitle(v);
  }

  Future<void> setForbidTag(bool v) async {
    state = state.copyWith(forbidTag: v);
    await _storage.setIsForbidTag(v);
  }

  Future<void> setForbidCategory(bool v) async {
    state = state.copyWith(forbidCategory: v);
    await _storage.setIsForbidCategory(v);
  }
}

final forbidWordsProvider =
    StateNotifierProvider<ForbidWordsNotifier, ForbidWordsState>((ref) {
  return ForbidWordsNotifier(ref.read(settingsStorageProvider));
});

/// 屏蔽词过滤器：在所有 `Comic` 列表加载处使用。
/// - 当 [state.selected] 为空时直接返回原列表；
/// - 否则根据勾选的过滤维度（标题 / 标签 / 分类）判断是否命中任一屏蔽词。
class ForbidWordsFilter {
  final ForbidWordsState state;

  const ForbidWordsFilter(this.state);

  List<Comic> apply(List<Comic> input) {
    if (state.selected.isEmpty) return input;
    return input.where((c) => !_isBlocked(c)).toList();
  }

  bool _isBlocked(Comic c) {
    final words = state.selected;
    if (state.forbidTitle) {
      for (final w in words) {
        if (w.isEmpty) continue;
        if (c.title.toLowerCase().contains(w.toLowerCase())) return true;
      }
    }
    // pica API 的漫画 tags 字段同时承载「分类 / Tag / 标签」三类元数据
    // 桌面端 CategoryMgr 是固定分类列表，移动端不做此区分，统一通过 tags 命中
    if (state.forbidCategory || state.forbidTag) {
      for (final w in words) {
        if (w.isEmpty) continue;
        for (final tag in c.tags) {
          if (tag.toLowerCase().contains(w.toLowerCase())) return true;
        }
      }
    }
    return false;
  }
}
