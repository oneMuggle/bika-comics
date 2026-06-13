import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_strings.dart';

/// 帮助 / 关于页 — 第八批新增
///
/// 对应桌面端 `view/help/help_view.py` 的核心信息子集：
/// - 版本号 + 包名
/// - 项目链接（GitHub）
/// - 反馈 / 邮箱
/// - 日志目录（点击复制路径）
/// - 协议致谢
///
/// 桌面端特有（未迁移）：
/// - 数据库热更新（仅维护者用）
/// - 调试用「打印日志窗口」（开发态）
/// - 一键检查更新（移动端改为跳 GitHub Releases）
class HelpScreen extends ConsumerStatefulWidget {
  const HelpScreen({super.key});

  @override
  ConsumerState<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends ConsumerState<HelpScreen> {
  PackageInfo? _info;
  String? _logDir;
  String? _downloadDir;
  bool _loading = true;

  static const _repoUrl = 'https://github.com/oneMuggle/bika-comics';
  static const _issuesUrl = 'https://github.com/oneMuggle/bika-comics/issues';
  static const _releasesUrl = 'https://github.com/oneMuggle/bika-comics/releases';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final docsDir = await getApplicationDocumentsDirectory();
      final supportDir = await getApplicationSupportDirectory();
      final tempDir = await getTemporaryDirectory();
      setState(() {
        _info = info;
        _logDir = docsDir.path;
        _downloadDir = '${docsDir.path}/downloads';
        _loading = false;
        // sanity check to silence unused warning on support/temp
        supportDir.path;
        tempDir.path;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _snack('无法打开：$url');
    }
  }

  Future<void> _copyToClipboard(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    _snack('已复制 $label');
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('帮助 / 关于'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildSection('版本信息', [
                  _kv('应用名称', _info?.appName ?? AppStrings.appName),
                  _kv('版本号', '${_info?.version ?? '?'} (${_info?.buildNumber ?? '?'})'),
                  _kv('包名', _info?.packageName ?? '-'),
                ]),
                _buildSection('项目链接', [
                  _tile(
                    Icons.code,
                    'GitHub 仓库',
                    '查看源码 / 提 PR',
                    () => _openUrl(_repoUrl),
                  ),
                  _tile(
                    Icons.bug_report_outlined,
                    '反馈问题',
                    'Issue 跟踪',
                    () => _openUrl(_issuesUrl),
                  ),
                  _tile(
                    Icons.system_update_alt,
                    '检查更新',
                    '前往 Releases 页',
                    () => _openUrl(_releasesUrl),
                  ),
                ]),
                _buildSection('本地数据', [
                  _tile(
                    Icons.folder_outlined,
                    '应用文档目录',
                    _logDir ?? '-',
                    () => _copyToClipboard(_logDir ?? '', '应用文档目录'),
                  ),
                  _tile(
                    Icons.download_outlined,
                    '下载文件目录',
                    _downloadDir ?? '-',
                    () => _copyToClipboard(_downloadDir ?? '', '下载目录'),
                  ),
                  _tile(
                    Icons.copy_all_outlined,
                    '复制全部路径',
                    '一键复制上述两个目录到剪贴板',
                    () => _copyToClipboard(
                      'docs=${_logDir ?? ''}\ndownloads=${_downloadDir ?? ''}',
                      '全部路径',
                    ),
                  ),
                ]),
                _buildSection('关于', [
                  _tile(
                    Icons.info_outline,
                    '简介',
                    AppStrings.appDesc,
                    null,
                  ),
                  _tile(
                    Icons.balance_outlined,
                    '开源协议',
                    'MIT License',
                    null,
                  ),
                  _tile(
                    Icons.handshake_outlined,
                    '数据来源',
                    '哔咔漫画 PicACG 公开 API',
                    null,
                  ),
                ]),
                _buildSection('桌面端对照', [
                  _tile(
                    Icons.swap_horiz,
                    '迁移进度',
                    '第八批：导出 / 帮助 落地；剩余：Waifu2x、远端 NAS 协议',
                    null,
                  ),
                ]),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    '哔咔漫画 · Flutter 移动端',
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.menu_book_rounded, size: 56, color: Colors.white),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  AppStrings.appName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.appDesc,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 16, 4),
          child: Text(
            title,
            style: TextStyle(
              color: AppColors.secondaryText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _kv(String key, String value) {
    return ListTile(
      dense: true,
      title: Text(key, style: const TextStyle(fontSize: 14)),
      trailing: Text(
        value,
        style: TextStyle(
          color: AppColors.secondaryText,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _tile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback? onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: AppColors.secondaryText,
          fontSize: 12,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: onTap == null
          ? null
          : const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}
