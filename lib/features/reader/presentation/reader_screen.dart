import 'dart:async';

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
import '../data/history_repository.dart';

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

  /// 初始页码（0-indexed）— 第十五批：历史恢复点
  /// 桌面端 `read_view.py` 在打开时传入保存的 pageIndex 启动阅读器
  final int initialPage;

  const ReaderScreen({
    super.key,
    required this.comicId,
    required this.episodes,
    required this.initialEpisodeIndex,
    this.initialPage = 0,
  });

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  late int _currentEpisodeIndex;
  late PageController _pageController;
  late ScrollController _verticalController;
  int _currentPage = 0;
  bool _showControls = true;
  _ReaderMode _readerMode = _ReaderMode.single;

  /// 第十五批：历史保存节流计时器
  Timer? _saveDebounce;
  /// 是否已经把初始页码回滚过（只在首次 build 后回滚一次）
  bool _didJumpToInitialPage = false;

  @override
  void initState() {
    super.initState();
    _currentEpisodeIndex = widget.initialEpisodeIndex;
    _currentPage = widget.initialPage;
    _pageController = PageController(initialPage: widget.initialPage);
    _verticalController = ScrollController();
    _verticalController.addListener(_onVerticalScroll);

    // 隐藏状态栏
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    // 最后一次保存 — 不等节流，避免用户退出阅读器时丢数据
    _saveDebounce?.cancel();
    _persistCurrentPosition();
    _verticalController.removeListener(_onVerticalScroll);
    _pageController.dispose();
    _verticalController.dispose();
    // 恢复状态栏
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  /// 第十五批：把 (comic, episode, page) 持久化到 history 表
  /// 节流 500ms — 避免频繁写库
  void _scheduleSavePosition() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 500), _persistCurrentPosition);
  }

  void _persistCurrentPosition() {
    if (!mounted) return;
    if (widget.episodes.isEmpty) return;
    if (_currentEpisodeIndex < 0 || _currentEpisodeIndex >= widget.episodes.length) {
      return;
    }
    final ep = widget.episodes[_currentEpisodeIndex];
    HistoryRepository.instance.saveReadingPosition(
      remoteComicId: widget.comicId,
      remoteEpisodeId: ep.id,
      page: _currentPage,
    );
  }

  void _onVerticalScroll() {
    // 同步页码到 _currentPage（粗略估计：page = scrollOffset / pageHeight）
    if (!_verticalController.hasClients) return;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final pageHeight = renderBox.size.height;
    if (pageHeight <= 0) return;
    final newPage = (_verticalController.offset / pageHeight).floor();
    if (newPage != _currentPage) {
      setState(() => _currentPage = newPage);
      _scheduleSavePosition();
    }
  }

  /// 第十五批：条状模式下恢复 initialPage 的滚动位置
  ///
  /// PageController(initialPage) 适用于 single 模式；
  /// vertical controller 没有 initialScrollOffset（其实有，但需要在第一次 build 后才有 RenderBox.height），
  /// 所以用 postFrameCallback 等 layout 完成后再滚。
  void _restoreScrollPositionIfNeeded() {
    if (_didJumpToInitialPage) return;
    if (widget.initialPage <= 0) {
      _didJumpToInitialPage = true;
      return;
    }
    if (_readerMode != _ReaderMode.strip) {
      _didJumpToInitialPage = true;
      return;
    }
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final h = renderBox.size.height;
    if (h <= 0) return;
    if (!_verticalController.hasClients) return;
    _verticalController.jumpTo(widget.initialPage * h);
    _didJumpToInitialPage = true;
  }

  comic.Episode get currentEpisode => widget.episodes[_currentEpisodeIndex];

  @override
  Widget build(BuildContext context) {
    final pagesAsync = ref.watch(episodePagesProvider((
      comicId: widget.comicId,
      episodeId: currentEpisode.id,
    )));

    // 第十五批：条状模式恢复滚动位置 — 等首次 build 完成
    if (!_didJumpToInitialPage && _readerMode == _ReaderMode.strip) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _restoreScrollPositionIfNeeded();
      });
    }

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
                  const Icon(Icons.error, color: AppColors.error, size: 48),
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
              child: _buildReaderView(pages),
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
                      icon: Icon(
                        _readerMode == _ReaderMode.single
                            ? Icons.swap_vert
                            : Icons.swap_horiz,
                      ),
                      tooltip: _readerMode == _ReaderMode.single
                          ? '切换到条状模式'
                          : '切换到单页模式',
                      onPressed: _toggleReaderMode,
                    ),
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
                              ? () {
                                  if (_readerMode == _ReaderMode.single) {
                                    _pageController.previousPage(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  } else {
                                    final renderBox = context
                                        .findRenderObject() as RenderBox?;
                                    if (renderBox != null) {
                                      final h = renderBox.size.height;
                                      if (h > 0) {
                                        _verticalController.animateTo(
                                          (_currentPage - 1) * h,
                                          duration:
                                              const Duration(milliseconds: 300),
                                          curve: Curves.easeInOut,
                                        );
                                      }
                                    }
                                  }
                                }
                              : null,
                        ),
                        GestureDetector(
                          onTap: () async {
                            // 提前捕获高度，避免 await 后使用 BuildContext
                            final renderBox =
                                context.findRenderObject() as RenderBox?;
                            final target = await _showPageDialog(
                                context, pages.length);
                            if (target != null && target >= 0) {
                              if (_readerMode == _ReaderMode.single) {
                                _pageController.jumpToPage(target);
                              } else {
                                // 条状模式：按页码 × 屏幕高度滚动
                                if (renderBox != null) {
                                  final h = renderBox.size.height;
                                  if (h > 0) {
                                    _verticalController.jumpTo(target * h);
                                  }
                                }
                              }
                              // 跳转后保存位置（节流）
                              _scheduleSavePosition();
                            }
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
                              ? () {
                                  if (_readerMode == _ReaderMode.single) {
                                    _pageController.nextPage(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  } else {
                                    final renderBox = context
                                        .findRenderObject() as RenderBox?;
                                    if (renderBox != null) {
                                      final h = renderBox.size.height;
                                      if (h > 0) {
                                        _verticalController.animateTo(
                                          (_currentPage + 1) * h,
                                          duration:
                                              const Duration(milliseconds: 300),
                                          curve: Curves.easeInOut,
                                        );
                                      }
                                    }
                                  }
                                }
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

  /// 根据当前模式构建阅读视图
  Widget _buildReaderView(List<String> pages) {
    switch (_readerMode) {
      case _ReaderMode.single:
        return PhotoViewGallery.builder(
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
            _scheduleSavePosition();
          },
          scrollPhysics: const BouncingScrollPhysics(),
          backgroundDecoration: const BoxDecoration(color: Colors.black),
        );
      case _ReaderMode.strip:
        return ListView.builder(
          controller: _verticalController,
          itemCount: pages.length,
          itemBuilder: (context, index) {
            return PhotoView(
              imageProvider: CachedNetworkImageProvider(pages[index]),
              backgroundDecoration:
                  const BoxDecoration(color: Colors.black),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 3,
              errorBuilder: (_, __, ___) => const SizedBox(
                height: 200,
                child: Center(
                  child: Icon(Icons.broken_image,
                      color: Colors.white54, size: 64),
                ),
              ),
            );
          },
        );
    }
  }

  /// 显示页码跳转对话框
  /// 返回目标页码（0-indexed），用户取消则返回 null
  Future<int?> _showPageDialog(BuildContext context, int totalPages) async {
    final controller = TextEditingController(
      text: '${_currentPage + 1}',
    );
    return showDialog<int?>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          titleTextStyle: const TextStyle(color: Colors.white, fontSize: 18),
          title: const Text('跳转到页码'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: '输入页码',
              hintStyle: TextStyle(color: Colors.white54),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
            ),
            onSubmitted: (val) {
              final page = int.tryParse(val);
              if (page != null && page >= 1 && page <= totalPages) {
                Navigator.pop(ctx, page - 1);
              }
            },
          ),
          contentTextStyle: const TextStyle(color: Colors.white70),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                final page = int.tryParse(controller.text);
                if (page != null && page >= 1 && page <= totalPages) {
                  Navigator.pop(ctx, page - 1);
                } else {
                  Navigator.pop(ctx, null);
                }
              },
              child: Text('跳转 (1-$totalPages)'),
            ),
          ],
        );
      },
    );
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
                        setState(() {
                          _currentEpisodeIndex = index;
                          _currentPage = 0;
                        });
                        _pageController.jumpToPage(0);
                        if (_verticalController.hasClients) {
                          _verticalController.jumpTo(0);
                        }
                        // 切换章节后立即保存（page = 0）
                        _scheduleSavePosition();
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

  /// 切换阅读模式
  void _toggleReaderMode() {
    setState(() {
      _readerMode =
          _readerMode == _ReaderMode.single ? _ReaderMode.strip : _ReaderMode.single;
      // 重置页码
      _currentPage = 0;
    });
    if (_readerMode == _ReaderMode.single) {
      if (_verticalController.hasClients) {
        _verticalController.jumpTo(0);
      }
    } else {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    }
    _scheduleSavePosition();
  }
}

/// 阅读器模式
/// - single: 单页横滑（PhotoViewGallery）
/// - strip:  条状/长条垂直滚动（PageView 内嵌 PhotoView，可缩放）
enum _ReaderMode { single, strip }
