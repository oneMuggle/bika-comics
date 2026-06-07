import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'comic_repository.dart';
import '../domain/comic_model.dart';

/// 批量搜索条目
class BatchSearchItem {
  final String keyword;
  final List<Comic> results;
  final bool isLoading;
  final String? error;
  final DateTime? finishedAt;

  const BatchSearchItem({
    required this.keyword,
    this.results = const [],
    this.isLoading = false,
    this.error,
    this.finishedAt,
  });

  BatchSearchItem copyWith({
    String? keyword,
    List<Comic>? results,
    bool? isLoading,
    String? error,
    DateTime? finishedAt,
  }) {
    return BatchSearchItem(
      keyword: keyword ?? this.keyword,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      finishedAt: finishedAt ?? this.finishedAt,
    );
  }
}

class BatchSearchState {
  final List<BatchSearchItem> items;
  final bool isRunning;

  const BatchSearchState({this.items = const [], this.isRunning = false});

  BatchSearchState copyWith({List<BatchSearchItem>? items, bool? isRunning}) {
    return BatchSearchState(
      items: items ?? this.items,
      isRunning: isRunning ?? this.isRunning,
    );
  }
}

class BatchSearchNotifier extends StateNotifier<BatchSearchState> {
  final ComicRepository _repo;
  BatchSearchNotifier(this._repo) : super(const BatchSearchState());

  void setKeywords(List<String> keywords) {
    final items = keywords
        .map((k) => BatchSearchItem(keyword: k.trim()))
        .where((i) => i.keyword.isNotEmpty)
        .toList();
    state = state.copyWith(items: items);
  }

  void addKeyword(String keyword) {
    final k = keyword.trim();
    if (k.isEmpty) return;
    if (state.items.any((i) => i.keyword == k)) return;
    state = state.copyWith(
      items: [...state.items, BatchSearchItem(keyword: k)],
    );
  }

  void removeKeyword(String keyword) {
    state = state.copyWith(
      items: state.items.where((i) => i.keyword != keyword).toList(),
    );
  }

  void clear() {
    state = const BatchSearchState();
  }

  /// 顺序执行批量搜索
  Future<void> runAll() async {
    if (state.isRunning || state.items.isEmpty) return;
    state = state.copyWith(isRunning: true);
    final updated = [...state.items];
    for (int i = 0; i < updated.length; i++) {
      updated[i] = updated[i].copyWith(
        isLoading: true,
        error: null,
      );
      state = state.copyWith(items: List.from(updated));
      try {
        final results = await _repo.search(q: updated[i].keyword);
        updated[i] = updated[i].copyWith(
          isLoading: false,
          results: results,
          finishedAt: DateTime.now(),
        );
      } catch (e) {
        updated[i] = updated[i].copyWith(
          isLoading: false,
          error: e.toString(),
          finishedAt: DateTime.now(),
        );
      }
      state = state.copyWith(items: List.from(updated));
    }
    state = state.copyWith(isRunning: false);
  }
}

final batchSearchProvider =
    StateNotifierProvider<BatchSearchNotifier, BatchSearchState>((ref) {
  return BatchSearchNotifier(ref.read(comicRepositoryProvider));
});
