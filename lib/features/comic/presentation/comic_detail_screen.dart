import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/api/api_client.dart';
import '../../../shared/constants/api_constants.dart';
import '../../../shared/constants/app_colors.dart';
import '../../reader/data/history_repository.dart';
import '../../reader/presentation/reader_screen.dart';
import '../data/comic_repository.dart';
import '../domain/comic_model.dart';
import 'comments_screen.dart';
import 'search_screen.dart';
import '../../download/data/download_repository.dart';
import '../../download/presentation/download_screen.dart';

/// 漫画详情 Provider
final comicDetailProvider =
    FutureProvider.family<ComicDetail, String>((ref, comicId) async {
  final api = ApiClient.instance;

  // 并行请求详情和章节列表
  final results = await Future.wait([
    api.get(ApiEndpoints.comicDetail(comicId)),
    api.get(ApiEndpoints.episodes(comicId)),
  ]);

  final comic = Comic.fromJson(results[0].data['data']);
  final epsData = results[1].data['data']['eps'];
  final episodes = (epsData['docs'] as List)
      .map((e) => Episode.fromJson(e))
      .toList();

  return ComicDetail(comic: comic, episodes: episodes);
});

/// 漫画相关推荐 Provider (GET /comics/{id}/recommendation)
final comicRecommendationProvider =
    FutureProvider.family<List<Comic>, String>((ref, comicId) async {
  final repo = ref.read(comicRepositoryProvider);
  try {
    return await repo.getComicRecommendation(comicId);
  } catch (_) {
    return const [];
  }
});

/// 漫画详情页
class ComicDetailScreen extends ConsumerWidget {
  final String comicId;

  const ComicDetailScreen({super.key, required this.comicId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDetail = ref.watch(comicDetailProvider(comicId));

    return Scaffold(
      body: asyncDetail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('加载失败: $e')),
        data: (detail) => CustomScrollView(
          slivers: [
            _buildAppBar(context, detail.comic),
            SliverToBoxAdapter(
              child: _buildInfo(context, detail.comic),
            ),
            SliverToBoxAdapter(
              child: _buildActionButtons(context, detail),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final episode = detail.episodes[index];
                  return _buildEpisodeTile(
                    context,
                    episode,
                    detail.episodes,
                    detail.comic.id,
                    index,
                    detail,
                  );
                },
                childCount: detail.episodes.length,
              ),
            ),
            // 相关推荐
            SliverToBoxAdapter(
              child: _buildRecommendationSection(context, ref, comicId),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationSection(
      BuildContext context, WidgetRef ref, String comicId) {
    final asyncRecs = ref.watch(comicRecommendationProvider(comicId));
    return asyncRecs.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (recs) {
        if (recs.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.recommend, color: AppColors.primary, size: 20),
                  SizedBox(width: 6),
                  Text(
                    '相关推荐',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 180,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: recs.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final c = recs[i];
                    return GestureDetector(
                      onTap: () {
                        // 跳转新的漫画详情：使用 pushReplacement 以避免返回栈累积
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) =>
                                ComicDetailScreen(comicId: c.id),
                          ),
                        );
                      },
                      child: SizedBox(
                        width: 110,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  c.coverUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: AppColors.darkCard,
                                    child: const Icon(Icons.broken_image),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              c.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context, Comic comic) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: CachedNetworkImage(
          imageUrl: comic.coverUrl,
          fit: BoxFit.cover,
          color: Colors.black45,
          colorBlendMode: BlendMode.darken,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share),
          tooltip: '分享',
          onPressed: () {
            // 第十五批：分享链接优先使用 pica+id 格式（与桌面端对齐）
            final shareLink = comic.shareId.isNotEmpty
                ? 'pica+${comic.shareId}'
                : 'https://picacomic.com/comic/${comic.id}';
            Share.share(
              '${comic.title}\n'
              '${comic.description.isNotEmpty ? "${comic.description}\n" : ""}'
              '$shareLink',
              subject: comic.title,
            );
          },
        ),
      ],
    );
  }

  Widget _buildInfo(BuildContext context, Comic comic) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  comic.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              // 第十五批：完结标记
              if (comic.finished)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(40),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.primary, width: 1),
                  ),
                  child: const Text(
                    '已完结',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // 第十五批：作者 / 上传者 / 汉化组 三行式元数据
          if (comic.author.isNotEmpty)
            _buildMetaRow(
              context,
              icon: Icons.person,
              label: '作者',
              value: comic.author,
              onTap: () => _openSearch(context, comic.author),
            ),
          if (comic.creator.isNotEmpty)
            _buildMetaRow(
              context,
              icon: Icons.upload,
              label: '上传',
              value: comic.creator,
              onTap: () => _openSearch(context, comic.creator),
            ),
          if (comic.chineseTeam.isNotEmpty)
            _buildMetaRow(
              context,
              icon: Icons.translate,
              label: '汉化',
              value: comic.chineseTeam,
              onTap: () => _openSearch(context, comic.chineseTeam),
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.visibility, size: 16, color: AppColors.secondaryText),
              const SizedBox(width: 4),
              Text('${comic.totalViews}',
                  style: const TextStyle(color: AppColors.secondaryText)),
              const SizedBox(width: 16),
              const Icon(Icons.favorite, size: 16, color: AppColors.secondaryText),
              const SizedBox(width: 4),
              Text('${comic.likeCount}',
                  style: const TextStyle(color: AppColors.secondaryText)),
              if (comic.pagesCount > 0) ...[
                const SizedBox(width: 16),
                const Icon(Icons.menu_book, size: 16, color: AppColors.secondaryText),
                const SizedBox(width: 4),
                Text('${comic.pagesCount}页',
                    style: const TextStyle(color: AppColors.secondaryText)),
              ],
            ],
          ),
          if (comic.updatedAt != null) ...[
            const SizedBox(height: 4),
            Text(
              '更新于 ${_formatDate(comic.updatedAt!)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.secondaryText,
              ),
            ),
          ],
          const SizedBox(height: 12),
          // 第十五批：标签可点击 → 搜索；不再 take(5)，全部展示
          if (comic.tags.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: comic.tags
                  .map((tag) => ActionChip(
                        label: Text(tag, style: const TextStyle(fontSize: 12)),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onPressed: () => _openSearch(context, tag),
                      ))
                  .toList(),
            ),
          const SizedBox(height: 12),
          Text(
            comic.description,
            style: const TextStyle(color: AppColors.secondaryText, fontSize: 14),
          ),
        ],
      ),
    );
  }

  /// 第十五批：元数据行（图标 + 标签 + 值；可选 onTap）
  Widget _buildMetaRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.secondaryText),
          const SizedBox(width: 4),
          Text(
            '$label:',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: content,
    );
  }

  /// 第十五批：打开搜索页（带初始关键词）
  void _openSearch(BuildContext context, String keyword) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SearchScreen(initialKeyword: keyword),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays < 1) return '今天';
    if (diff.inDays < 30) return '${diff.inDays}天前';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  /// 第十五批：根据远程 episodeId 在列表里找下标（找不到时返回 0）
  int _findEpisodeIndex(List<Episode> episodes, String remoteEpisodeId) {
    for (int i = 0; i < episodes.length; i++) {
      if (episodes[i].id == remoteEpisodeId) return i;
    }
    return 0;
  }

  /// 第十五批：根据是否有历史决定按钮文案
  String _readingLabel(ComicDetail detail, BuildContext context) {
    // 注：context 在 onPressed 异步回调里没用，但保留以备扩展
    final count = detail.comic.episodeCount;
    return '开始阅读 ($count章)';
  }

  Widget _buildActionButtons(BuildContext context, ComicDetail detail) {
    final repo = ProviderScope.containerOf(context).read(comicRepositoryProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () async {
                // 第十五批：先查历史决定 initialPage
                final history = await HistoryRepository.instance
                    .getContinueReadingForRemoteComicId(detail.comic.id);
                final initialEpisodeIndex = history == null
                    ? 0
                    : _findEpisodeIndex(detail.episodes, history.remoteEpisodeId);
                final initialPage = history?.lastPage ?? 0;
                if (!context.mounted) return;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ReaderScreen(
                      comicId: detail.comic.id,
                      episodes: detail.episodes,
                      initialEpisodeIndex: initialEpisodeIndex.clamp(0, detail.episodes.length - 1),
                      initialPage: initialPage,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.play_arrow),
              label: Text(_readingLabel(detail, context)),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                if (detail.comic.isFavourite) {
                  await repo.unfavourite(detail.comic.id);
                } else {
                  await repo.favourite(detail.comic.id);
                }
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(detail.comic.isFavourite ? '已取消收藏' : '已收藏'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('操作失败: $e')),
                );
              }
            },
            icon: Icon(
              detail.comic.isFavourite ? Icons.favorite : Icons.favorite_border,
              color: detail.comic.isFavourite ? Colors.red : null,
            ),
            tooltip: '收藏',
          ),
          IconButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                if (detail.comic.isFollowed) {
                  await repo.unfollow(detail.comic.id);
                } else {
                  await repo.follow(detail.comic.id);
                }
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(detail.comic.isFollowed ? '已取消追漫' : '已追漫'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('操作失败: $e')),
                );
              }
            },
            icon: Icon(
              detail.comic.isFollowed ? Icons.bookmark : Icons.bookmark_border,
              color: detail.comic.isFollowed ? Colors.blue : null,
            ),
            tooltip: '追漫',
          ),
          IconButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                await repo.like(detail.comic.id);
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('已点赞'),
                    duration: Duration(seconds: 1),
                  ),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('操作失败: $e')),
                );
              }
            },
            icon: const Icon(Icons.thumb_up_outlined),
            tooltip: '点赞',
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const DownloadsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.download_outlined),
            tooltip: '下载管理',
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CommentsScreen(comicId: detail.comic.id),
                ),
              );
            },
            icon: const Icon(Icons.comment_outlined),
            tooltip: '评论',
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodeTile(BuildContext context, Episode episode, List<Episode> episodes, String comicId, int index, ComicDetail detail) {
    return ListTile(
      leading: CircleAvatar(
        child: Text('${episode.order}'),
      ),
      title: Text(episode.title),
      subtitle: episode.publishedAt != null
          ? Text(
              '${episode.publishedAt!.year}-${episode.publishedAt!.month.toString().padLeft(2, '0')}-${episode.publishedAt!.day.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 12),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.download, size: 20),
            onPressed: () => _downloadEpisode(context, episode, detail.comic),
            tooltip: '下载此章节',
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ReaderScreen(
              comicId: comicId,
              episodes: episodes,
              initialEpisodeIndex: index,
            ),
          ),
        );
      },
    );
  }

  Future<void> _downloadEpisode(BuildContext context, Episode episode, Comic comic) async {
    final repo = ProviderScope.containerOf(context).read(downloadRepositoryProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('下载章节'),
        content: Text('确定下载《${comic.title}》的第${episode.order}章吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await repo.addEpisodeDownload(
          comicId: comic.id,
          episodeId: episode.id,
          episodeTitle: episode.title,
          title: comic.title,
          coverUrl: comic.coverUrl,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已开始下载第${episode.order}章'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('下载失败: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
