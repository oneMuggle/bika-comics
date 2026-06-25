import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// ZIP / CBZ 漫画包条目
class ZipImageEntry {
  /// 在压缩包内的相对路径（用于调试 / 信息展示）
  final String entryName;

  /// 图片字节
  final Uint8List bytes;

  /// 解压后体积（字节）
  final int sizeBytes;

  const ZipImageEntry({
    required this.entryName,
    required this.bytes,
    required this.sizeBytes,
  });
}

/// 解析结果
class ZipExtractionResult {
  final List<ZipImageEntry> entries;
  final int? firstErrorCode;
  final String? errorMessage;

  const ZipExtractionResult.success(this.entries)
      : firstErrorCode = null,
        errorMessage = null;

  const ZipExtractionResult.failure(this.errorMessage, {this.firstErrorCode})
      : entries = const [];

  bool get isSuccess => entries.isNotEmpty && errorMessage == null;
  bool get isEmpty => entries.isEmpty;
}

/// ZIP / CBZ 漫画包解析器 — 第十三批「本地图片阅读器支持 ZIP/CBZ 漫画包」
///
/// 对应桌面端：
/// - `view/tool/local_read_view.py` — 拖入 / 选择 .zip / .cbz 解析
/// - `task/task_local.py#ParseBookInfoByFile` — 解析 ZIP 内的图片清单
///
/// 桌面端实现：
/// 1. `zipfile.is_zipfile(path)` 校验
/// 2. 遍历 `zfile.infolist()`，跳过目录、过滤非图片扩展名
/// 3. 优先选择「子目录中图片数 ≥ 2」的目录（避免单图封面 / 杂项文件）
/// 4. 自然顺序排序图片名
/// 5. 逐张 `f.read(filename)` 读取
///
/// 移动端实现要点：
/// - 不写入磁盘（避免权限 / 存储管理问题）
/// - 一次性解码到 `Uint8List`，由 `ZipReaderScreen` 用 `MemoryImage` 渲染
/// - 体积上限 500 张图（与 `nas_local_screen.dart` 的 `_collectImages` 一致）
class ZipExtractor {
  /// 常见图片扩展名（小写）
  static const Set<String> imageExtensions = {
    '.jpg', '.jpeg', '.png', '.webp', '.gif', '.bmp', '.heic', '.avif',
  };

  /// 单包体积硬上限（解压后总字节数），超过则放弃读取，防止 OOM
  /// 500 MB — 普通漫画包约 100-300 MB
  static const int maxTotalBytes = 500 * 1024 * 1024;

  /// 单包条目硬上限
  static const int maxEntryCount = 500;

  /// 错误码
  static const int errNotZip = 1;
  static const int errEncrypted = 2;
  static const int errNoImages = 3;
  static const int errTooLarge = 4;
  static const int errIo = 5;

  /// 解析一个 ZIP / CBZ 文件
  ///
  /// 返回 [ZipExtractionResult]。可能为：
  /// - `success`：`entries` 按自然顺序排列的图片列表
  /// - `failure`：`errorMessage` 给中文说明 + `firstErrorCode` 编程用
  static Future<ZipExtractionResult> extract(String zipPath) async {
    final file = File(zipPath);
    if (!await file.exists()) {
      return const ZipExtractionResult.failure('文件不存在', firstErrorCode: errIo);
    }

    final Uint8List bytes;
    try {
      bytes = await file.readAsBytes();
    } on FileSystemException catch (e) {
      return ZipExtractionResult.failure('文件系统错误: ${e.message}', firstErrorCode: errIo);
    }

    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } on Exception catch (e) {
      final msg = e.toString();
      if (msg.contains('encrypted') || msg.contains('Encrypted')) {
        return const ZipExtractionResult.failure('加密的压缩包暂不支持', firstErrorCode: errEncrypted);
      }
      return ZipExtractionResult.failure('无法读取压缩包: $msg', firstErrorCode: errNotZip);
    }

    if (archive.isEmpty) {
      return const ZipExtractionResult.failure('压缩包为空', firstErrorCode: errNoImages);
    }

    // 第一遍：按子目录聚合图片，与桌面端 `ParseBookInfoByFile` 行为一致
    final dirPictures = <String, List<ArchiveFile>>{};
    for (final f in archive.files) {
      if (!f.isFile) continue;
      if (f.size <= 0) continue;

      final filename = f.name;
      final dot = filename.lastIndexOf('.');
      if (dot < 0) continue;
      final ext = filename.substring(dot).toLowerCase();
      if (!imageExtensions.contains(ext)) continue;

      // 用正斜杠分割，统一路径分隔符
      final normalized = filename.replaceAll(r'\', '/');
      final parent = normalized.contains('/')
          ? normalized.substring(0, normalized.lastIndexOf('/'))
          : '';
      dirPictures.putIfAbsent(parent, () => []).add(f);
    }

    // 选择「子目录中图片数 ≥ 2」的最大子目录；全在根目录则用根
    String chosenDir = '';
    int maxCount = 0;
    dirPictures.forEach((dir, list) {
      if (list.length > maxCount) {
        maxCount = list.length;
        chosenDir = dir;
      }
    });

    final chosen = dirPictures[chosenDir];
    if (chosen == null || chosen.isEmpty) {
      return const ZipExtractionResult.failure('压缩包内未发现图片', firstErrorCode: errNoImages);
    }

    // 第二遍：自然顺序排序
    chosen.sort((a, b) => _naturalCompare(a.name, b.name));

    if (chosen.length > maxEntryCount) {
      return const ZipExtractionResult.failure(
        '图片数超过上限 $maxEntryCount',
        firstErrorCode: errTooLarge,
      );
    }

    // 第三遍：读取字节
    int totalBytes = 0;
    final entries = <ZipImageEntry>[];
    for (final f in chosen) {
      try {
        final content = f.content;
        if (content is! Uint8List) {
          return const ZipExtractionResult.failure(
            '图片内容类型不支持',
            firstErrorCode: errIo,
          );
        }
        totalBytes += content.length;
        if (totalBytes > maxTotalBytes) {
          return const ZipExtractionResult.failure(
            '解压后总大小超过 ${maxTotalBytes ~/ 1024 ~/ 1024} MB',
            firstErrorCode: errTooLarge,
          );
        }
        entries.add(ZipImageEntry(
          entryName: f.name,
          bytes: content,
          sizeBytes: content.length,
        ));
      } on Exception catch (e) {
        return ZipExtractionResult.failure('读取图片失败: $e', firstErrorCode: errIo);
      }
    }

    if (entries.isEmpty) {
      return const ZipExtractionResult.failure('压缩包内未发现图片', firstErrorCode: errNoImages);
    }

    return ZipExtractionResult.success(entries);
  }

  /// 简易自然顺序比较：数字感知，与 `nas_local_screen._naturalCompare` 一致
  static int _naturalCompare(String a, String b) {
    final aBase = a.split('/').last;
    final bBase = b.split('/').last;
    int i = 0, j = 0;
    while (i < aBase.length && j < bBase.length) {
      final ac = aBase.codeUnitAt(i);
      final bc = bBase.codeUnitAt(j);
      if (ac >= 0x30 && ac <= 0x39 && bc >= 0x30 && bc <= 0x39) {
        // 数字段比较
        int aEnd = i;
        while (aEnd < aBase.length && aBase.codeUnitAt(aEnd) >= 0x30 && aBase.codeUnitAt(aEnd) <= 0x39) {
          aEnd++;
        }
        int bEnd = j;
        while (bEnd < bBase.length && bBase.codeUnitAt(bEnd) >= 0x30 && bBase.codeUnitAt(bEnd) <= 0x39) {
          bEnd++;
        }
        final aNum = aBase.substring(i, aEnd);
        final bNum = bBase.substring(j, bEnd);
        // 长度不等时按数值比；等长时按字典比（保持稳定）
        if (aNum.length != bNum.length) {
          final cmp = BigInt.parse(aNum).compareTo(BigInt.parse(bNum));
          if (cmp != 0) return cmp;
        } else {
          final cmp = aNum.compareTo(bNum);
          if (cmp != 0) return cmp;
        }
        i = aEnd;
        j = bEnd;
      } else {
        final cmp = ac.compareTo(bc);
        if (cmp != 0) return cmp;
        i++;
        j++;
      }
    }
    return aBase.length - bBase.length;
  }
}
