import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../../shared/constants/app_colors.dart';

/// NAS 本地阅读 — 移动端迁移起步
///
/// 对应桌面端 `view/nas/nas_view.py` + `view/nas/nas_db.py` + `view/nas/nas_add_view.py`
///
/// 桌面端 NAS 是「SFTP / WebDAV / 局域网共享」客户端：用户在 `nas_add_view` 中填
/// 远端地址、端口、协议、用户密码，写入本地 SQLite `nas.db`（`nas_info` 表 +
/// `nas_upload` 上传任务表），主界面表格列出已配 NAS 及其下的漫画，并支持
/// 上传 / 同步 / 读取本地下载。
///
/// 移动端的运行环境（沙箱、权限、跨平台）差异较大，无法 1:1 复制。本期先落地
/// 「应用沙箱目录 + 文档目录 / 缓存目录 / 外部存储目录」三个路径的只读展示，
/// 构成后续接入 SFTP / WebDAV / smb 客户端（如 `dart_smbclient` /
/// `dartssh2` / `webdav_client`）的脚手架。
class NasLocalScreen extends StatefulWidget {
  const NasLocalScreen({super.key});

  @override
  State<NasLocalScreen> createState() => _NasLocalScreenState();
}

class _NasLocalScreenState extends State<NasLocalScreen> {
  late Future<List<_NasDirEntry>> _dirsFuture;

  @override
  void initState() {
    super.initState();
    _dirsFuture = _loadDirs();
  }

  Future<List<_NasDirEntry>> _loadDirs() async {
    final entries = <_NasDirEntry>[];
    Future<void> add(String title, Future<Directory?> Function() loader) async {
      try {
        final dir = await loader();
        if (dir == null) return;
        final exists = await dir.exists();
        entries.add(_NasDirEntry(
          title: title,
          path: dir.path,
          exists: exists,
          size: exists ? await _dirSize(dir) : 0,
        ));
      } catch (e) {
        entries.add(_NasDirEntry(
          title: title,
          path: '<加载失败: $e>',
          exists: false,
          size: 0,
          error: true,
        ));
      }
    }

    await add('应用文档目录 (getApplicationDocumentsDirectory)',
        () => getApplicationDocumentsDirectory());
    await add('应用支持目录 (getApplicationSupportDirectory)',
        () => getApplicationSupportDirectory());
    await add('临时缓存目录 (getTemporaryDirectory)',
        () => getTemporaryDirectory());
    // getExternalStorageDirectory 仅 Android 可用，其它平台可能抛 PlatformException
    try {
      await add('外部存储目录 (getExternalStorageDirectory, Android)',
          () => getExternalStorageDirectory());
    } catch (_) {
      // iOS / 桌面端不支持，忽略
    }
    return entries;
  }

  Future<int> _dirSize(Directory dir) async {
    int total = 0;
    await for (final entity in dir.list(followLinks: false, recursive: false)) {
      try {
        if (entity is File) {
          total += await entity.length();
        }
      } catch (_) {
        // 单个文件无权限时跳过
      }
    }
    return total;
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
        title: const Text('本地阅读（NAS）'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
            onPressed: () {
              setState(() {
                _dirsFuture = _loadDirs();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 说明区
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppColors.primary.withAlpha(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                    SizedBox(width: 6),
                    Text('移动端 NAS 起步说明',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  '• 当前版本只读展示应用沙箱内的本地目录；\n'
                  '• 后续可接入 SFTP / WebDAV / SMB 客户端，参考桌面端 view/nas/ 协议；\n'
                  '• 移动端阅读器（reader_screen）已支持本地图片路径输入。',
                  style: TextStyle(fontSize: 12, height: 1.5),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // 目录列表
          Expanded(
            child: FutureBuilder<List<_NasDirEntry>>(
              future: _dirsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('加载失败: ${snapshot.error}'));
                }
                final entries = snapshot.data ?? const [];
                if (entries.isEmpty) {
                  return const Center(child: Text('未发现可用目录'));
                }
                return ListView.separated(
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final e = entries[index];
                    return ListTile(
                      leading: Icon(
                        e.error
                            ? Icons.error_outline
                            : e.exists
                                ? Icons.folder_open
                                : Icons.folder_off_outlined,
                        color: e.error
                            ? AppColors.error
                            : e.exists
                                ? AppColors.primary
                                : Colors.grey,
                      ),
                      title: Text(e.title),
                      subtitle: Text(
                        e.path,
                        style: const TextStyle(fontSize: 11),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: e.error
                          ? null
                          : Text(
                              e.exists ? _formatSize(e.size) : '不存在',
                              style: TextStyle(
                                fontSize: 12,
                                color: e.exists ? null : Colors.grey,
                              ),
                            ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NasDirEntry {
  final String title;
  final String path;
  final bool exists;
  final int size;
  final bool error;
  const _NasDirEntry({
    required this.title,
    required this.path,
    required this.exists,
    required this.size,
    this.error = false,
  });
}
