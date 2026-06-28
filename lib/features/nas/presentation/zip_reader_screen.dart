import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../../../shared/constants/app_colors.dart';
import '../data/zip_extractor.dart';

/// ZIP / CBZ 漫画包阅读器 — 第十三批「本地图片阅读器支持 ZIP/CBZ 漫画包」
///
/// 与 [LocalReaderScreen] 的区别：
/// - 输入是 `List<ZipImageEntry>`（解压后的内存字节），不是磁盘文件路径
/// - 使用 `MemoryImage` 而非 `FileImage`
/// - 多一个「解析来源」提示（文件名）显示在 AppBar 副标题
///
/// 解析工作由 `ZipExtractor.extract` 异步完成（带 loading dialog）。
class ZipReaderScreen extends StatefulWidget {
  /// 预解压的图片条目（按自然顺序）
  final List<ZipImageEntry> entries;

  /// 起始页码
  final int initialIndex;

  /// 顶部标题（一般是 ZIP 文件名）
  final String title;

  /// ZIP 文件路径（用于 AppBar 副标题显示）
  final String? sourcePath;

  const ZipReaderScreen({
    super.key,
    required this.entries,
    this.initialIndex = 0,
    this.title = 'ZIP 漫画包',
    this.sourcePath,
  });

  @override
  State<ZipReaderScreen> createState() => _ZipReaderScreenState();
}

enum _ZipReaderMode { single, strip }

class _ZipReaderScreenState extends State<ZipReaderScreen> {
  late PageController _pageController;
  late ScrollController _verticalController;
  late int _currentPage;
  bool _showControls = true;
  _ZipReaderMode _mode = _ZipReaderMode.single;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialIndex.clamp(0, widget.entries.length - 1);
    _pageController = PageController(initialPage: _currentPage);
    _verticalController = ScrollController();
    _verticalController.addListener(_onVerticalScroll);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _verticalController.removeListener(_onVerticalScroll);
    _pageController.dispose();
    _verticalController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _onVerticalScroll() {
    if (!_verticalController.hasClients) return;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final pageHeight = renderBox.size.height;
    if (pageHeight <= 0) return;
    final newPage = (_verticalController.offset / pageHeight).floor();
    if (newPage != _currentPage && newPage >= 0 && newPage < widget.entries.length) {
      setState(() => _currentPage = newPage);
    }
  }

  void _toggleMode() {
    setState(() {
      _mode =
          _mode == _ZipReaderMode.single ? _ZipReaderMode.strip : _ZipReaderMode.single;
    });
  }

  Future<int?> _showPageDialog() async {
    final controller = TextEditingController(text: '${_currentPage + 1}');
    return showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('跳转到页码'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '1 - ${widget.entries.length}',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final v = int.tryParse(controller.text);
              if (v != null && v >= 1 && v <= widget.entries.length) {
                Navigator.pop(ctx, v - 1);
              }
            },
            child: const Text('跳转'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.entries.length;
    if (total == 0) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Text(widget.title),
        ),
        body: const Center(
          child: Text('没有可显示的图片', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => setState(() => _showControls = !_showControls),
            child: _mode == _ZipReaderMode.single
                ? _buildSingleMode()
                : _buildStripMode(),
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
                    widget.title,
                    style: const TextStyle(fontSize: 16),
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(
                        _mode == _ZipReaderMode.single
                            ? Icons.swap_vert
                            : Icons.swap_horiz,
                      ),
                      tooltip: _mode == _ZipReaderMode.single
                          ? '切换到条状模式'
                          : '切换到单页模式',
                      onPressed: _toggleMode,
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.skip_previous, color: Colors.white),
                        onPressed: _currentPage > 0
                            ? () {
                                if (_mode == _ZipReaderMode.single) {
                                  _pageController.previousPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                } else {
                                  final box = context.findRenderObject() as RenderBox?;
                                  final h = box?.size.height ?? 0;
                                  if (h > 0) {
                                    _verticalController.animateTo(
                                      (_currentPage - 1) * h,
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  }
                                }
                              }
                            : null,
                      ),
                      GestureDetector(
                        onTap: () async {
                          // 提前捕获高度，避免 await 后使用 BuildContext
                          final h =
                              (context.findRenderObject() as RenderBox?)?.size.height ?? 0;
                          final target = await _showPageDialog();
                          if (target != null && mounted) {
                            if (_mode == _ZipReaderMode.single) {
                              _pageController.jumpToPage(target);
                            } else {
                              if (h > 0) _verticalController.jumpTo(target * h);
                            }
                            setState(() => _currentPage = target);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(80),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${_currentPage + 1} / $total',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next, color: Colors.white),
                        onPressed: _currentPage < total - 1
                            ? () {
                                if (_mode == _ZipReaderMode.single) {
                                  _pageController.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                } else {
                                  final box = context.findRenderObject() as RenderBox?;
                                  final h = box?.size.height ?? 0;
                                  if (h > 0) {
                                    _verticalController.animateTo(
                                      (_currentPage + 1) * h,
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  }
                                }
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleMode() {
    return PhotoViewGallery.builder(
      pageController: _pageController,
      itemCount: widget.entries.length,
      onPageChanged: (i) => setState(() => _currentPage = i),
      backgroundDecoration: const BoxDecoration(color: Colors.black),
      builder: (context, index) {
        return PhotoViewGalleryPageOptions(
          imageProvider: MemoryImage(widget.entries[index].bytes),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 4,
          heroAttributes: PhotoViewHeroAttributes(
            tag: 'zip_${widget.title}_$index',
          ),
        );
      },
      loadingBuilder: (context, _) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  Widget _buildStripMode() {
    return ListView.builder(
      controller: _verticalController,
      itemCount: widget.entries.length,
      itemBuilder: (context, index) {
        return Image.memory(
          widget.entries[index].bytes,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Container(
            height: 200,
            color: Colors.grey.shade900,
            alignment: Alignment.center,
            child: Text(
              '图片加载失败 (${index + 1}): $error',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        );
      },
    );
  }
}
