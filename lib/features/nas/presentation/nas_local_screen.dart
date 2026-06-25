import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../../shared/constants/app_colors.dart';
import '../data/zip_extractor.dart';
import 'local_reader_screen.dart';
import 'zip_reader_screen.dart';

/// NAS 本地阅读 — 移动端迁移第七批（文件浏览器）
///
/// 对应桌面端：
/// - `view/nas/nas_view.py` — 列出已配 NAS 表格
/// - `view/nas/nas_db.py` — NAS SQLite 配置
/// - `view/nas/nas_item.py` — 单一 NAS 节点浏览
/// - `view/tool/local_fold_view.py` — 本地文件夹浏览
/// - `view/tool/local_eps_read_view.py` — 本地章节阅读
/// - `view/tool/local_read_view.py` / `local_read_all_view.py` — 本地全本/单本阅读
///
/// 移动端运行环境（沙箱、权限、跨平台）差异较大，本期实现：
/// 1. 沙箱根目录列表（应用文档 / 支持 / 临时 / 外部存储）
/// 2. 递归子目录浏览（点击进入子目录、长按查看属性）
/// 3. 自动识别「图片文件夹」：含 ≥1 张常见图片格式时显示「阅读」按钮
/// 4. 点击「阅读」启动 `LocalReaderScreen`，按文件名自然顺序展示
///
/// 远端 SFTP / WebDAV / SMB 客户端暂未接入（依赖第三方包）。
class NasLocalScreen extends StatefulWidget {
  const NasLocalScreen({super.key});

  @override
  State<NasLocalScreen> createState() => _NasLocalScreenState();
}

class _NasLocalScreenState extends State<NasLocalScreen> {
  /// 当前浏览路径（null = 沙箱根）
  String? _currentPath;
  bool _loading = false;
  String? _error;
  List<_FileSystemEntry> _entries = const [];

  static const _imageExtensions = {
    '.jpg', '.jpeg', '.png', '.webp', '.gif', '.bmp', '.heic', '.avif',
  };

  /// ZIP / CBZ 漫画包扩展名（与桌面端 `view/tool/local_read_view.py` 解析一致）
  static const _zipExtensions = {
    '.zip', '.cbz',
  };

  @override
  void initState() {
    super.initState();
    _loadRoot();
  }

  Future<void> _loadRoot() async {
    setState(() {
      _currentPath = null;
      _loading = true;
      _error = null;
    });
    try {
      final roots = await _loadSandboxRoots();
      setState(() {
        _entries = roots;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<List<_FileSystemEntry>> _loadSandboxRoots() async {
    final roots = <_FileSystemEntry>[];
    Future<void> add(String title, Future<Directory?> Function() loader) async {
      try {
        final dir = await loader();
        if (dir == null) return;
        final exists = await dir.exists();
        roots.add(_FileSystemEntry(
          name: title,
          path: dir.path,
          isDirectory: true,
          exists: exists,
          sizeBytes: exists ? await _dirSizeFlat(dir) : 0,
        ));
      } catch (e) {
        roots.add(_FileSystemEntry(
          name: title,
          path: '<加载失败: $e>',
          isDirectory: true,
          exists: false,
          error: true,
        ));
      }
    }

    await add('应用文档目录 (Documents)', () => getApplicationDocumentsDirectory());
    await add('应用支持目录 (Application Support)', () => getApplicationSupportDirectory());
    await add('临时缓存目录 (Temporary)', () => getTemporaryDirectory());
    try {
      await add('外部存储目录 (External Storage, Android)', () => getExternalStorageDirectory());
    } catch (_) {
      // iOS / 桌面端不支持
    }
    return roots;
  }

  Future<void> _enterDir(String path) async {
    setState(() {
      _loading = true;
      _error = null;
      _currentPath = path;
    });
    try {
      final dir = Directory(path);
      if (!await dir.exists()) {
        throw FileSystemException('目录不存在', path);
      }
      final list = <_FileSystemEntry>[];
      await for (final entity in dir.list(followLinks: false, recursive: false)) {
        try {
          if (entity is Directory) {
            final subCount = await _dirCountShallow(entity);
            list.add(_FileSystemEntry(
              name: _basename(entity.path),
              path: entity.path,
              isDirectory: true,
              exists: true,
              childCount: subCount,
            ));
          } else if (entity is File) {
            final size = await entity.length();
            list.add(_FileSystemEntry(
              name: _basename(entity.path),
              path: entity.path,
              isDirectory: false,
              exists: true,
              sizeBytes: size,
            ));
          }
        } catch (_) {
          // 单个实体无权限，跳过
        }
      }
      // 文件夹排前，文件排后；同组内按自然名（数字感知）排序
      list.sort((a, b) {
        if (a.isDirectory != b.isDirectory) {
          return a.isDirectory ? -1 : 1;
        }
        return _naturalCompare(a.name, b.name);
      });
      setState(() {
        _entries = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<int> _dirSizeFlat(Directory dir) async {
    int total = 0;
    await for (final entity in dir.list(followLinks: false, recursive: false)) {
      if (entity is File) {
        try {
          total += await entity.length();
        } catch (_) {}
      }
    }
    return total;
  }

  Future<int> _dirCountShallow(Directory dir) async {
    int count = 0;
    try {
      await for (final _ in dir.list(followLinks: false, recursive: false)) {
        count++;
      }
    } catch (_) {}
    return count;
  }

  String _basename(String path) {
    final i = path.lastIndexOf(Platform.pathSeparator);
    if (i < 0 || i == path.length - 1) return path;
    return path.substring(i + 1);
  }

  int _naturalCompare(String a, String b) {
    // 数字感知比较：file2 < file10
    final regex = RegExp(r'(\d+)|(\D+)');
    final aParts = regex.allMatches(a).toList();
    final bParts = regex.allMatches(b).toList();
    final len = aParts.length < bParts.length ? aParts.length : bParts.length;
    for (int i = 0; i < len; i++) {
      final ap = aParts[i].group(0)!;
      final bp = bParts[i].group(0)!;
      final aIsNum = RegExp(r'^\d+$').hasMatch(ap);
      final bIsNum = RegExp(r'^\d+$').hasMatch(bp);
      if (aIsNum && bIsNum) {
        final cmp = BigInt.parse(ap).compareTo(BigInt.parse(bp));
        if (cmp != 0) return cmp;
      } else {
        final cmp = ap.toLowerCase().compareTo(bp.toLowerCase());
        if (cmp != 0) return cmp;
      }
    }
    return a.length - b.length;
  }

  /// 收集当前目录下（含第一层子目录中）的所有图片（最多 [maxFiles] 个以防 OOM）
  Future<List<String>> _collectImages(String dirPath, {int maxFiles = 500}) async {
    final images = <String>[];
    Future<void> walk(String path) async {
      if (images.length >= maxFiles) return;
      final dir = Directory(path);
      if (!await dir.exists()) return;
      await for (final entity in dir.list(followLinks: false, recursive: false)) {
        if (images.length >= maxFiles) return;
        if (entity is File && _isImage(entity.path)) {
          images.add(entity.path);
        } else if (entity is Directory) {
          // 仅下钻一层，避免把整个磁盘扫穿
          await walk(entity.path);
        }
      }
    }

    await walk(dirPath);
    images.sort((a, b) => _naturalCompare(_basename(a), _basename(b)));
    return images;
  }

  bool _isImage(String path) {
    final lower = path.toLowerCase();
    return _imageExtensions.any(lower.endsWith);
  }

  bool _isZip(String path) {
    final lower = path.toLowerCase();
    return _zipExtensions.any(lower.endsWith);
  }

  Future<void> _openAsReader(String dirPath, String title) async {
    final images = await _collectImages(dirPath);
    if (!mounted) return;
    if (images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('该目录中没有发现可识别的图片文件')),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LocalReaderScreen(
          imagePaths: images,
          initialIndex: 0,
          title: title,
        ),
      ),
    );
  }

  /// 打开一个 ZIP / CBZ 漫画包：解析 → 解压到内存 → 启动 ZipReaderScreen
  ///
  /// 对应桌面端 `view/tool/local_read_view.py#CheckAction2` 的核心交互：
  ///   1. `QFileDialog` 选 .zip / .cbz
  ///   2. `ParseBookInfoByFile` 校验 + 解析
  ///   3. `LocalEpsReadView` 启动阅读
  ///
  /// 移动端用 loading dialog 替代 QtOwner.ShowLoading()，错误用 SnackBar 替代 Log.Error。
  Future<void> _openAsZipReader(String zipPath, String title) async {
    if (!mounted) return;

    // 显示 loading dialog（仿 QtOwner().ShowLoading()）
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const PopScope(
        canPop: false,
        child: Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('正在解析压缩包...'),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final result = await ZipExtractor.extract(zipPath);

    if (!mounted) return;
    // 关闭 loading
    Navigator.of(context, rootNavigator: true).pop();

    if (!result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorMessage ?? '解析失败')),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ZipReaderScreen(
          entries: result.entries,
          initialIndex: 0,
          title: title,
          sourcePath: zipPath,
        ),
      ),
    );
  }

  void _showProperties(_FileSystemEntry entry) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _propRow('类型', entry.isDirectory ? '目录' : '文件'),
              _propRow('路径', entry.path),
              if (entry.isDirectory)
                _propRow('直属子项', entry.childCount >= 0 ? '${entry.childCount}' : '—'),
              if (!entry.isDirectory)
                _propRow('大小', _formatSize(entry.sizeBytes)),
              if (entry.error) _propRow('状态', '加载失败'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _propRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  String _formatSize(int bytes) {
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
        title: Text(_currentPath == null ? '本地阅读（NAS）' : _basename(_currentPath!)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
            onPressed: () {
              if (_currentPath == null) {
                _loadRoot();
              } else {
                _enterDir(_currentPath!);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_currentPath != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: Colors.black12,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _currentPath!,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _openAsReader(
                      _currentPath!,
                      _basename(_currentPath!),
                    ),
                    icon: const Icon(Icons.menu_book_outlined, size: 16),
                    label: const Text('阅读此目录'),
                  ),
                ],
              ),
            ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: AppColors.primary.withAlpha(20),
            child: const Text(
              '• 点击目录进入下一级；\n'
              '• 长按文件/目录查看属性；\n'
              '• 顶栏「阅读此目录」将自动扫描第一层子目录中的图片并启动阅读器；\n'
              '• 点击 .zip / .cbz 漫画包可解压阅读（不写入磁盘）；\n'
              '• 远端 SFTP / WebDAV / SMB 客户端后续接入。',
              style: TextStyle(fontSize: 11, height: 1.5),
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _buildBody()),
        ],
      ),
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
          child: Text('加载失败: $_error', textAlign: TextAlign.center),
        ),
      );
    }
    if (_entries.isEmpty) {
      return const Center(child: Text('当前目录为空'));
    }
    return ListView.separated(
      itemCount: _entries.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final e = _entries[index];
        return ListTile(
          leading: _buildLeading(e),
          title: Text(
            e.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            e.isDirectory
                ? (e.childCount >= 0 ? '${e.childCount} 个子项' : '—')
                : _formatSize(e.sizeBytes),
            style: const TextStyle(fontSize: 11),
          ),
          trailing: e.isDirectory
              ? const Icon(Icons.chevron_right, color: Colors.grey)
              : null,
          onTap: e.isDirectory
              ? () => _enterDir(e.path)
              : () {
                  if (_isZip(e.path)) {
                    _openAsZipReader(e.path, e.name);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${e.name} — ${_formatSize(e.sizeBytes)}')),
                    );
                  }
                },
          onLongPress: () => _showProperties(e),
        );
      },
    );
  }

  Widget _buildLeading(_FileSystemEntry e) {
    if (e.error) {
      return const Icon(Icons.error_outline, color: AppColors.error);
    }
    if (!e.exists) {
      return const Icon(Icons.folder_off_outlined, color: Colors.grey);
    }
    if (e.isDirectory) {
      return const Icon(Icons.folder_open, color: AppColors.primary);
    }
    if (_isZip(e.path)) {
      return const Icon(Icons.folder_zip_outlined, color: Colors.orange);
    }
    if (_isImage(e.path)) {
      return const Icon(Icons.image_outlined, color: Colors.green);
    }
    return const Icon(Icons.insert_drive_file_outlined, color: Colors.grey);
  }
}

class _FileSystemEntry {
  final String name;
  final String path;
  final bool isDirectory;
  final bool exists;
  final bool error;
  final int sizeBytes;
  final int childCount;

  const _FileSystemEntry({
    required this.name,
    required this.path,
    required this.isDirectory,
    required this.exists,
    this.error = false,
    this.sizeBytes = 0,
    this.childCount = -1,
  });
}
