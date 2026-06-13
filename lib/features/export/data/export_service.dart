import 'dart:io';

import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// 导出格式
enum ExportFormat {
  zip, // ZIP 压缩
  raw, // 原图列表（多文件 share）
}

/// 单个导出章节的信息
class ExportableEpisode {
  final String episodeId;
  final String title;
  final Directory directory;
  final List<File> imageFiles;

  const ExportableEpisode({
    required this.episodeId,
    required this.title,
    required this.directory,
    required this.imageFiles,
  });

  /// 总大小（字节）
  int get totalSizeBytes =>
      imageFiles.fold(0, (sum, f) => sum + f.lengthSync());

  String get totalSizeText => _formatSize(totalSizeBytes);

  static String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
  }
}

/// 导出结果
class ExportResult {
  final bool success;
  final File? outputFile;
  final List<File> outputFiles;
  final String? error;
  final int fileCount;
  final int totalSizeBytes;

  const ExportResult({
    required this.success,
    this.outputFile,
    this.outputFiles = const [],
    this.error,
    this.fileCount = 0,
    this.totalSizeBytes = 0,
  });

  static ExportResult failure(String error) => ExportResult(
        success: false,
        error: error,
      );
}

/// 导出服务 — 第八批新增
///
/// 对应桌面端 `view/convert/convert_view.py` + `task/task_convert_zip.py`：
/// 把已下载章节的图片打包为 ZIP / 多文件，便于分享 / 备份 / 拷贝到 PC。
///
/// 桌面端 convert 还包含：
/// - 转 EPUB（桌面端用 ebooklib，体积较大，移动端暂不集成）
/// - 上传到 SMB / WebDAV（对应 `view/nas/`，移动端第七批已做本地预览）
///
/// 本期只覆盖「ZIP 打包 + 系统分享」这一核心移动端场景。
class ExportService {
  /// 已下载漫画在沙箱里的根目录
  Future<Directory> getDownloadRoot() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/downloads');
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// 临时导出目录（用于 ZIP 中转）
  Future<Directory> getExportTempDir() async {
    final tempDir = await getTemporaryDirectory();
    final dir = Directory('${tempDir.path}/exports');
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// 列出某已下载漫画下所有「可导出」章节
  ///
  /// 返回的图片按 `0001.jpg, 0002.jpg, ...` 自然顺序排列（下载时已 padLeft）
  Future<List<ExportableEpisode>> listDownloadableEpisodes(
    String comicId, {
    String comicTitle = '',
  }) async {
    final root = await getDownloadRoot();
    final comicDir = Directory('${root.path}/$comicId');
    if (!comicDir.existsSync()) return [];

    final episodes = <ExportableEpisode>[];
    final subdirs = comicDir
        .listSync()
        .whereType<Directory>()
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    for (final sub in subdirs) {
      final files = sub
          .listSync()
          .whereType<File>()
          .where((f) => _isImageFile(f.path))
          .toList()
        ..sort((a, b) => _naturalCompare(a.path, b.path));

      if (files.isEmpty) continue;

      episodes.add(ExportableEpisode(
        episodeId: sub.path.split('/').last,
        title: sub.path.split('/').last,
        directory: sub,
        imageFiles: files,
      ));
    }
    return episodes;
  }

  /// 把单章节打包为 ZIP
  ///
  /// - 进度回调：0.0 → 1.0
  /// - 返回 ZIP 文件路径（位于 temp/exports/）
  Future<ExportResult> exportEpisodeToZip(
    ExportableEpisode episode, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      final tempDir = await getExportTempDir();
      final safeName = _sanitizeFilename(episode.title);
      final zipPath = '${tempDir.path}/${safeName}_${episode.episodeId}.zip';
      final zipFile = File(zipPath);

      // 已存在则删除（避免追加）
      if (zipFile.existsSync()) {
        await zipFile.delete();
      }

      final encoder = ZipFileEncoder();
      encoder.create(zipPath);

      final total = episode.imageFiles.length;
      int processed = 0;
      for (final img in episode.imageFiles) {
        final name = img.uri.pathSegments.last;
        await encoder.addFile(img, name);
        processed += 1;
        onProgress?.call(total > 0 ? processed / total : 1.0);
      }
      encoder.close();

      final outFile = File(zipPath);
      return ExportResult(
        success: true,
        outputFile: outFile,
        fileCount: total,
        totalSizeBytes: outFile.lengthSync(),
      );
    } catch (e) {
      return ExportResult.failure(e.toString());
    }
  }

  /// 把单章节的所有图片直接分享（多文件 share sheet）
  Future<ExportResult> exportEpisodeRaw(
    ExportableEpisode episode,
  ) async {
    try {
      final files = episode.imageFiles;
      if (files.isEmpty) {
        return ExportResult.failure('该章节没有图片可分享');
      }
      return ExportResult(
        success: true,
        outputFiles: files,
        fileCount: files.length,
        totalSizeBytes:
            files.fold(0, (sum, f) => sum + f.lengthSync()),
      );
    } catch (e) {
      return ExportResult.failure(e.toString());
    }
  }

  /// 系统分享 ZIP
  Future<void> shareZip(File zipFile, {String? subject}) async {
    await Share.shareXFiles(
      [XFile(zipFile.path)],
      subject: subject ?? '哔咔漫画导出',
      text: '哔咔漫画导出章节：${zipFile.uri.pathSegments.last}',
    );
  }

  /// 系统分享多张原图
  Future<void> shareImages(List<File> files, {String? subject}) async {
    await Share.shareXFiles(
      files.map((f) => XFile(f.path)).toList(),
      subject: subject ?? '哔咔漫画导出',
    );
  }

  // ---- helpers ----

  static bool _isImageFile(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif');
  }

  /// 自然名排序：file2 < file10
  static int _naturalCompare(String a, String b) {
    final reg = RegExp(r'(\d+)|(\D+)');
    final aParts = reg.allMatches(a).toList();
    final bParts = reg.allMatches(b).toList();
    final len = aParts.length < bParts.length ? aParts.length : bParts.length;
    for (int i = 0; i < len; i++) {
      final aStr = aParts[i].group(0)!;
      final bStr = bParts[i].group(0)!;
      final aNum = int.tryParse(aStr);
      final bNum = int.tryParse(bStr);
      if (aNum != null && bNum != null) {
        if (aNum != bNum) return aNum.compareTo(bNum);
      } else {
        final cmp = aStr.compareTo(bStr);
        if (cmp != 0) return cmp;
      }
    }
    return a.length.compareTo(b.length);
  }

  /// 文件名清洗：去掉路径分隔符和特殊字符
  static String _sanitizeFilename(String name) {
    return name
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .trim();
  }
}
