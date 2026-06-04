import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/constants/app_colors.dart';
import '../../../shared/widgets/cached_image.dart';
import '../data/game_comments_repository.dart';
import '../data/game_repository.dart';
import '../domain/game_model.dart';

/// 游戏详情页面
///
/// 对应桌面端: src/view/info/game_info_view.py
/// - 显示标题、图标、描述、平台徽章、截图
/// - 桌面端点击截图进入 Waifu2x 工具；移动端简化为点击大图浏览
/// - 提供 Android / iOS 下载链接复制
class GameDetailScreen extends ConsumerWidget {
  final String gameId;
  const GameDetailScreen({super.key, required this.gameId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(gameDetailProvider(gameId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('游戏详情'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text('加载失败: $e',
                  style: TextStyle(color: AppColors.secondaryText)),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(gameDetailProvider(gameId)),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
        data: (game) => _DetailBody(game: game),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final Game game;
  const _DetailBody({required this.game});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部：图标 + 标题 + 平台徽章
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 120,
                  height: 120,
                  child: CachedImage(
                    imageUrl: game.icon.url,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (game.publisher.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        game.publisher,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                    if (game.version.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        '版本: ${game.version}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                    if (game.size.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        '大小: ${game.size}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (game.suggest) _Badge('推荐', Colors.orange),
                        if (game.adult) _Badge('R18', Colors.red),
                        if (game.android) _Badge('Android', Colors.green),
                        if (game.ios) _Badge('iOS', Colors.blue),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 下载按钮区
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: game.androidLinks.isEmpty
                      ? null
                      : () => _showLinkSheet(context, game.androidLinks, 'Android'),
                  icon: const Icon(Icons.android),
                  label: const Text('Android 下载'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: game.iosLinks.isEmpty
                      ? null
                      : () => _showLinkSheet(context, game.iosLinks, 'iOS'),
                  icon: const Icon(Icons.phone_iphone),
                  label: const Text('iOS 下载'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // 描述
          const Text(
            '简介',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            game.description.isEmpty ? '暂无简介' : game.description,
            style: const TextStyle(fontSize: 14, height: 1.6),
          ),
          // 截图
          if (game.screenshots.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              '截图',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 220,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: game.screenshots.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final s = game.screenshots[index];
                  return GestureDetector(
                    onTap: () => _openScreenshot(context, s),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedImage(
                        imageUrl: s.url,
                        width: 140,
                        height: 220,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          // 评论
          const SizedBox(height: 24),
          GameCommentsSection(gameId: game.id),
          // 底部留白
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showLinkSheet(
      BuildContext context, List<String> links, String label) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '$label 下载链接',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const Divider(height: 1),
              ...links.map((link) {
                return ListTile(
                  leading: const Icon(Icons.link),
                  title: Text(
                    link,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    final uri = Uri.tryParse(link);
                    if (uri == null) return;
                    final ok = await launchUrl(uri,
                        mode: LaunchMode.externalApplication);
                    if (!context.mounted) return;
                    if (!ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('无法打开链接: $link')),
                      );
                    }
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.copy),
                    tooltip: '复制',
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: link));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('已复制到剪贴板')),
                      );
                    },
                  ),
                );
              }),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _openScreenshot(BuildContext context, GameIcon s) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: Center(
            child: InteractiveViewer(
              maxScale: 4,
              child: CachedImage(
                imageUrl: s.url,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
