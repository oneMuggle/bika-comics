import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../../../core/api/api_client.dart';
import '../../../shared/constants/api_constants.dart';
import '../../../shared/constants/app_colors.dart';
import '../../comic/domain/comic_model.dart' as comic;

/// 阅读器 Provider
final episodePagesProvider =
    FutureProvider.family<List<String>, ({String comicId, String episodeId})>(
        (ref, params) async {
  final api = ApiClient.instance;
  final response = await api.get(
    ApiEndpoints.episodePages(params.comicId, params.episodeId),
  );
  final data = response.data['data'];
  // 返回图片 URL 列表
  final pages = (data['pages']['docs'] as List)
      .map<String>((p) => p['media']['path'] ?? p['media']['url'] ?? '')
      .where((url) => url.isNotEmpty)
      .toList();
  return pages;
});

/// 阅读器页面
class ReaderScreen extends ConsumerStatefulWidget {
  final String comicId;
  final List<comic.Episode> episodes;
  final int initialEpisodeIndex;

  const ReaderScreen({
    super.key,
    required this.comicId,
    required this.episodes,
    required this.initialEpisodeIndex,
  });

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  late int _currentEpisodeIndex;
  late PageController _pageController;
  int _currentPage = 0;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _currentEpisodeIndex = widget.initialEpisodeIndex;
    _pageController = PageController();

    // 隐藏状态栏
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _pageController.dispose();
    // 恢复状态栏
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  comic.Episode get currentEpisode => widget.episodes[_currentEpisodeIndex];

  @override
  Widget build(BuildContext context) {
    final pagesAsync = ref.watch(episodePagesProvider((
      comicId: widget.comicId,
      episodeId: currentEpisode.id,
    )));

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 图片画廊
          pagesAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            error: (e, s) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, color: AppColors.error, size: 48),
                  const SizedBox(height: 16),
                  Text('加载失败: $e',
                      style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () =>
                        ref.invalidate(episodePagesProvider((
                      comicId: widget.comicId,
                      episodeId: currentEpisode.id,
                    ))),
                    child: const Text('重试'),
                  ),
                ],
              ),
            ),
            data: (pages) => GestureDetector(
              onTap: () {
                setState(() => _showControls = !_showControls);
              },
              child: PhotoViewGallery.builder(
                pageController: _pageController,
                itemCount: pages.length,
                builder: (context, index) {
                  return PhotoViewGalleryPageOptions(
                    imageProvider: CachedNetworkImageProvider(pages[index]),
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered * 3,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image,
                          color: Colors.white54, size: 64),
                    ),
                  );
                },
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                scrollPhysics: const BouncingScrollPhysics(),
                backgroundDecoration: const BoxDecoration(color: Colors.black),
              ),
            ),
          ),

          // 顶部控制栏
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            top: _showControls ? 0 : -100,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(200),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: AppBar(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  title: Text(
                    currentEpisode.title,
                    style: const TextStyle(fontSize: 16),
                  ),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.list),
                      onPressed: () => _showEpisodePicker(context),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 底部页码
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            bottom: _showControls ? 0 : -80,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withAlpha(200),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: pagesAsync.maybeWhen(
                    data: (pages) => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.skip_previous,
                              color: Colors.white),
                          onPressed: _currentPage > 0
                              ? () => _pageController.previousPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  )
                              : null,
                        ),
                        GestureDetector(
                          onTap: () {
                            _pageController.jumpToPage(
                              _showPageDialog(context, pages.length),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_currentPage + 1} / ${pages.length}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_next, color: Colors.white),
                          onPressed: _currentPage < pages.length - 1
                              ? () => _pageController.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  )
                              : null,
                        ),
                      ],
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _showPageDialog(BuildContext context, int totalPages) {
    // 简单的页码跳转
    return _currentPage;
  }

  void _showEpisodePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '章节列表',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: widget.episodes.length,
                itemBuilder: (context, index) {
                  final ep = widget.episodes[index];
                  final isCurrent = index == _currentEpisodeIndex;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          isCurrent ? AppColors.primary : Colors.grey,
                      child: Text('${ep.order}'),
                    ),
                    title: Text(
                      ep.title,
                      style: TextStyle(
                        color: isCurrent ? AppColors.primary : null,
                        fontWeight: isCurrent ? FontWeight.bold : null,
                      ),
                    ),
                    trailing: isCurrent ? const Icon(Icons.play_arrow) : null,
                    onTap: () {
                      Navigator.of(context).pop();
                      if (index != _currentEpisodeIndex) {
                        setState(() => _currentEpisodeIndex = index);
                        _pageController.jumpToPage(0);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
