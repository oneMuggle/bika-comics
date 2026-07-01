import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/constants/app_colors.dart';
import '../data/export_service.dart';

/// 导出 / 分享屏幕 — 第八批新增
///
/// 对应桌面端 `view/convert/convert_view.py` 中「把已下载章节打包为 ZIP」
/// 的核心场景。EPUB 转码、SMB / WebDAV 上传等桌面端专属能力在移动端
/// 暂无等效替代。
///
/// 入口：
/// - 下载管理 → 详情底部面板 → 「导出此章节」按钮
/// - 漫画详情 → 已下载章节 → 长按 → 「导出分享」
///
/// 流程：
/// 1. 列出本漫画下所有已下载章节
/// 2. 用户选择章节
/// 3. 用户选择格式：ZIP 压缩 / 原图列表
/// 4. 调用系统分享面板（share_plus）
class ExportScreen extends ConsumerStatefulWidget {
  final String comicId;
  final String comicTitle;

  const ExportScreen({
    super.key,
    required this.comicId,
    required this.comicTitle,
  });

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  final _service = ExportService();
  List<ExportableEpisode> _episodes = const [];
  bool _loading = true;
  String? _error;

  // 进度状态：'zip:episodeId'
  String _exportingKey = '';
  double _exportingProgress = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _service.listDownloadableEpisodes(
        widget.comicId,
        comicTitle: widget.comicTitle,
      );
      setState(() {
        _episodes = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _exportAsZip(ExportableEpisode ep) async {
    setState(() {
      _exportingKey = 'zip:${ep.episodeId}';
      _exportingProgress = 0;
    });
    final result = await _service.exportEpisodeToZip(
      ep,
      onProgress: (p) {
        if (mounted) setState(() => _exportingProgress = p);
      },
    );
    if (!mounted) return;
    setState(() => _exportingKey = '');

    if (!result.success) {
      _snack('导出失败：${result.error}');
      return;
    }
    _snack('已生成 ${result.fileCount} 张图的 ZIP（${_humanSize(result.totalSizeBytes)}）');
    await _service.shareZip(
      result.outputFile!,
      subject: '${widget.comicTitle} - ${ep.title}',
    );
  }

  Future<void> _exportRaw(ExportableEpisode ep) async {
    setState(() {
      _exportingKey = 'raw:${ep.episodeId}';
      _exportingProgress = 0;
    });
    final result = await _service.exportEpisodeRaw(ep);
    if (!mounted) return;
    setState(() => _exportingKey = '');

    if (!result.success) {
      _snack('准备失败：${result.error}');
      return;
    }
    await _service.shareImages(
      result.outputFiles,
      subject: '${widget.comicTitle} - ${ep.title}',
    );
  }

  void _showExportSheet(ExportableEpisode ep) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.archive_outlined),
              title: const Text('打包为 ZIP'),
              subtitle: Text('${ep.imageFiles.length} 张图，${ep.totalSizeText}'),
              onTap: () {
                Navigator.pop(ctx);
                _exportAsZip(ep);
              },
            ),
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('直接分享原图'),
              subtitle: Text('${ep.imageFiles.length} 张图，${ep.totalSizeText}'),
              onTap: () {
                Navigator.pop(ctx);
                _exportRaw(ep);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _humanSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('导出 — ${widget.comicTitle}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            tooltip: '刷新',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('加载失败：$_error', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _load, child: const Text('重试')),
            ],
          ),
        ),
      );
    }
    if (_episodes.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text('该漫画尚未下载任何章节，无法导出'),
              SizedBox(height: 4),
              Text(
                '请先在阅读器或漫画详情页中下载章节',
                style: TextStyle(color: AppColors.secondaryText),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      itemCount: _episodes.length,
      itemBuilder: (context, i) => _buildEpisodeTile(_episodes[i]),
    );
  }

  Widget _buildEpisodeTile(ExportableEpisode ep) {
    final isExportingZip = _exportingKey == 'zip:${ep.episodeId}';
    final isExportingRaw = _exportingKey == 'raw:${ep.episodeId}';
    final isExporting = isExportingZip || isExportingRaw;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 1,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: const Icon(Icons.collections_bookmark_outlined,
              color: AppColors.primary),
        ),
        title: Text(
          ep.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('${ep.imageFiles.length} 张图 · ${ep.totalSizeText}'),
        ),
        trailing: isExporting
            ? SizedBox(
                width: 32,
                height: 32,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        value: isExportingZip ? _exportingProgress : null,
                        strokeWidth: 2,
                      ),
                    ),
                  ],
                ),
              )
            : const Icon(Icons.ios_share),
        onTap: isExporting ? null : () => _showExportSheet(ep),
      ),
    );
  }
}
