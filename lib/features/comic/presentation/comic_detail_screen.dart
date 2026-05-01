import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../shared/constants/api_constants.dart';
import '../../../shared/constants/app_colors.dart';
import '../../reader/presentation/reader_screen.dart';
import '../data/comic_repository.dart';
import '../domain/comic_model.dart';

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
                  );
                },
                childCount: detail.episodes.length,
              ),
            ),
          ],
        ),
      ),
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
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.favorite_border),
          onPressed: () {},
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
          Text(
            comic.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.person, size: 16, color: AppColors.secondaryText),
              const SizedBox(width: 4),
              Text(comic.author, style: TextStyle(color: AppColors.secondaryText)),
              const SizedBox(width: 16),
              Icon(Icons.visibility, size: 16, color: AppColors.secondaryText),
              const SizedBox(width: 4),
              Text('${comic.totalViews}',
                  style: TextStyle(color: AppColors.secondaryText)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: comic.tags
                .take(5)
                .map((tag) => Chip(
                      label: Text(tag, style: const TextStyle(fontSize: 12)),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          Text(
            comic.description,
            style: TextStyle(color: AppColors.secondaryText, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ComicDetail detail) {
    final repo = ProviderScope.containerOf(context).read(comicRepositoryProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ReaderScreen(
                      comicId: detail.comic.id,
                      episodes: detail.episodes,
                      initialEpisodeIndex: 0,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.play_arrow),
              label: Text('开始阅读 (${detail.comic.episodeCount}章)'),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () async {
              try {
                if (detail.comic.isFavourite) {
                  await repo.unfavourite(detail.comic.id);
                } else {
                  await repo.favourite(detail.comic.id);
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(detail.comic.isFavourite ? '已取消收藏' : '已收藏'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
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
              try {
                if (detail.comic.isFollowed) {
                  await repo.unfollow(detail.comic.id);
                } else {
                  await repo.follow(detail.comic.id);
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(detail.comic.isFollowed ? '已取消追漫' : '已追漫'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
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
              try {
                await repo.like(detail.comic.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('已点赞'),
                    duration: Duration(seconds: 1),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('操作失败: $e')),
                );
              }
            },
            icon: const Icon(Icons.thumb_up_outlined),
            tooltip: '点赞',
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodeTile(BuildContext context, Episode episode, List<Episode> episodes, String comicId, int index) {
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
      trailing: const Icon(Icons.chevron_right),
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
}
