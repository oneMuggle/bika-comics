import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../../../shared/constants/app_colors.dart';

/// 本地阅读器 — 纯本地图片文件夹阅读（不对应漫画 API）
///
/// 对应桌面端 `view/tool/local_eps_read_view.py` + `local_read_all_view.py` +
/// `local_read_view.py` 的核心交互。
///
/// 与 `features/reader/presentation/reader_screen.dart` 的区别：
/// - 不调用 `episodePagesProvider`（API 拉取），图片来自本地文件
/// - 不需要登录态 / token / 章节切换
/// - 提供「上一层」按钮 + 文件夹标题
class LocalReaderScreen extends StatefulWidget {
  /// 本地图片文件绝对路径列表（按文件名自然顺序）
  final List<String> imagePaths;

  /// 起始页码
  final int initialIndex;

  /// 顶部标题（一般是文件夹名）
  final String title;

  const LocalReaderScreen({
    super.key,
    required this.imagePaths,
    this.initialIndex = 0,
    this.title = '本地阅读',
  });

  @override
  State<LocalReaderScreen> createState() => _LocalReaderScreenState();
}

enum _LocalReaderMode { single, strip }

class _LocalReaderScreenState extends State<LocalReaderScreen> {
  late PageController _pageController;
  late ScrollController _verticalController;
  late int _currentPage;
  bool _showControls = true;
  _LocalReaderMode _mode = _LocalReaderMode.single;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialIndex.clamp(0, widget.imagePaths.length - 1);
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
    if (newPage != _currentPage && newPage >= 0 && newPage < widget.imagePaths.length) {
      setState(() => _currentPage = newPage);
    }
  }

  void _toggleMode() {
    setState(() {
      _mode =
          _mode == _LocalReaderMode.single ? _LocalReaderMode.strip : _LocalReaderMode.single;
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
            hintText: '1 - ${widget.imagePaths.length}',
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
              if (v != null && v >= 1 && v <= widget.imagePaths.length) {
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
    final total = widget.imagePaths.length;
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
            child: _mode == _LocalReaderMode.single
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
                        _mode == _LocalReaderMode.single
                            ? Icons.swap_vert
                            : Icons.swap_horiz,
                      ),
                      tooltip: _mode == _LocalReaderMode.single
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
                                if (_mode == _LocalReaderMode.single) {
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
                          final target = await _showPageDialog();
                          if (target != null && mounted) {
                            if (_mode == _LocalReaderMode.single) {
                              _pageController.jumpToPage(target);
                            } else {
                              final h =
                                  (context.findRenderObject() as RenderBox?)?.size.height ?? 0;
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
                                if (_mode == _LocalReaderMode.single) {
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
      itemCount: widget.imagePaths.length,
      onPageChanged: (i) => setState(() => _currentPage = i),
      backgroundDecoration: const BoxDecoration(color: Colors.black),
      builder: (context, index) {
        return PhotoViewGalleryPageOptions(
          imageProvider: FileImage(File(widget.imagePaths[index])),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 4,
          heroAttributes: PhotoViewHeroAttributes(tag: widget.imagePaths[index]),
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
      itemCount: widget.imagePaths.length,
      itemBuilder: (context, index) {
        return Image.file(
          File(widget.imagePaths[index]),
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
