import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/constants/app_colors.dart';
import '../../../shared/widgets/cached_image.dart';
import '../data/pica_apps_repository.dart';
import '../domain/pica_app_model.dart';

/// Pica Apps 第三方应用/客户端列表
///
/// 第十七批:对齐桌面端 `GetAPPsReq` (GET /pica-apps)
/// - 桌面端 settings_view.py 的 meunToolGroup(`showOpenSrSelect`) 会跳到 URL
/// - 移动端提供一个独立页面,在侧边栏可访问
///
/// 注意:
/// - 响应数据不是分页格式,直接返回 list (桌面端 `isParseRes=False`)
/// - 列表项点击 -> 通过 url_launcher 跳转到对应下载页
class PicaAppsScreen extends ConsumerWidget {
  const PicaAppsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(picaAppsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pica Apps'),
        actions: [
          IconButton(
            tooltip: '刷新',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(picaAppsListProvider),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(
          message: '$e',
          onRetry: () => ref.invalidate(picaAppsListProvider),
        ),
        data: (apps) {
          if (apps.isEmpty) {
            return const _EmptyState();
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(picaAppsListProvider);
              await ref.read(picaAppsListProvider.future);
            },
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: apps.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) => _PicaAppTile(app: apps[index]),
            ),
          );
        },
      ),
    );
  }
}

/// 单个 Pica App 列表项
class _PicaAppTile extends StatelessWidget {
  final PicaApp app;
  const _PicaAppTile({required this.app});

  Future<void> _open(BuildContext context) async {
    if (!app.isClickable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('该应用没有可用的链接')),
      );
      return;
    }
    final uri = Uri.tryParse(app.url);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('无效的链接: ${app.url}')),
      );
      return;
    }
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('无法打开链接: ${app.url}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('打开失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconUrl = app.icon.url;
    final hasIcon = iconUrl.isNotEmpty;

    return ListTile(
      leading: SizedBox(
        width: 48,
        height: 48,
        child: hasIcon
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedImage(
                  imageUrl: iconUrl,
                  fit: BoxFit.cover,
                  width: 48,
                  height: 48,
                ),
              )
            : Container(
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.apps,
                  color: AppColors.primary,
                  size: 26,
                ),
              ),
      ),
      title: Text(
        app.title.isEmpty ? '(未命名)' : app.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (app.description.isNotEmpty)
            Text(
              app.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.secondaryText,
              ),
            ),
          if (app.platform.isNotEmpty || app.url.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                children: [
                  if (app.platform.isNotEmpty) ...[
                    Icon(
                      _platformIcon(app.platform),
                      size: 12,
                      color: AppColors.secondaryText,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      app.platform,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                  if (app.platform.isNotEmpty && app.url.isNotEmpty)
                    const SizedBox(width: 8),
                  if (app.url.isNotEmpty)
                    Expanded(
                      child: Text(
                        app.url,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
      trailing: const Icon(Icons.open_in_new, size: 18),
      onTap: app.isClickable ? () => _open(context) : null,
    );
  }

  static IconData _platformIcon(String platform) {
    final p = platform.toLowerCase();
    if (p.contains('android')) return Icons.android;
    if (p.contains('ios') || p.contains('apple')) return Icons.apple;
    if (p.contains('web') || p.contains('http')) return Icons.public;
    return Icons.devices;
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.apps_outlined, size: 56, color: AppColors.secondaryText),
          SizedBox(height: 12),
          Text(
            '暂无可推荐的第三方应用',
            style: TextStyle(color: AppColors.secondaryText),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              '加载失败: $message',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.secondaryText),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}
