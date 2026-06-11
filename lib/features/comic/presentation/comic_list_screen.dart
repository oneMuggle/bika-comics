import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../shared/constants/api_constants.dart';
import '../../../shared/widgets/comic_card.dart';
import '../data/forbid_words_filter_helper.dart';
import '../domain/comic_model.dart';
import 'comic_detail_screen.dart';

/// 漫画列表 Provider
final comicListProvider = FutureProvider.family<List<Comic>, int>((ref, page) async {
  final api = ApiClient.instance;
  final response = await api.get(ApiEndpoints.comicsList(page: page));
  final data = response.data['data'];
  final comics = (data['comics'] as List)
      .map((json) => Comic.fromJson(json))
      .toList();
  return comics;
});

/// 漫画列表页
class ComicListScreen extends ConsumerStatefulWidget {
  const ComicListScreen({super.key});

  @override
  ConsumerState<ComicListScreen> createState() => _ComicListScreenState();
}

class _ComicListScreenState extends ConsumerState<ComicListScreen> {
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  List<Comic> _comics = [];
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadMore();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);
    try {
      final api = ApiClient.instance;
      final response = await api.get(ApiEndpoints.comicsList(page: _currentPage));
      final data = response.data['data'];
      final comics = (data['comics'] as List)
          .map((json) => Comic.fromJson(json))
          .toList();
      if (comics.isEmpty) {
        _hasMore = false;
      } else {
        setState(() {
          _comics.addAll(comics);
          _currentPage++;
        });
      }
    } catch (_) {
      _hasMore = false;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onRefresh() async {
    setState(() {
      _currentPage = 1;
      _comics = [];
      _hasMore = true;
    });
    await _loadMore();
  }

  @override
  Widget build(BuildContext context) {
    // 屏蔽词过滤（仅在设置变更时重新计算，命中效率高）
    final displayList = ref.watch(filteredComicsProvider(_comics));
    return Scaffold(
      appBar: AppBar(
        title: const Text('哔咔漫画'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // TODO: 跳转阅读历史
            },
          ),
        ],
      ),
      body: displayList.isEmpty && _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _onRefresh,
              child: displayList.isEmpty
                  ? ListView(
                      // ListView 让 RefreshIndicator 仍可下拉
                      children: const [
                        SizedBox(height: 120),
                        Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('没有可显示的漫画',
                                style: TextStyle(color: Colors.grey)),
                          ),
                        ),
                      ],
                    )
                  : GridView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(12),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.65,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: displayList.length + (_isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= displayList.length) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        final comic = displayList[index];
                        return ComicCard(
                          id: comic.id,
                          title: comic.title,
                          coverUrl: comic.coverUrl,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    ComicDetailScreen(comicId: comic.id),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
    );
  }
}
