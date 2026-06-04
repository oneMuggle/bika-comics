import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/widgets/cached_image.dart';

/// 游戏评论 Repository（独立于漫画评论 — 端点不同）
class GameCommentsRepository {
  final _api = ApiClient.instance;

  /// GET /games/{id}/comments?page=N
  Future<List<GameComment>> getComments(String gameId, {int page = 1}) async {
    final response = await _api.get(
      '/games/$gameId/comments',
      queryParameters: {'page': page},
    );
    final data = response.data is Map ? response.data['data'] : null;
    final docs = (data is Map && data['comments'] is Map)
        ? (data['comments']['docs'] as List? ?? const [])
        : (data is Map && data['docs'] is List)
            ? (data['docs'] as List? ?? const [])
            : const [];
    return docs
        .whereType<Map>()
        .map((m) => GameComment.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  /// POST /games/{id}/comments
  Future<void> sendComment(String gameId, String content) async {
    await _api.post(
      '/games/$gameId/comments',
      data: {'content': content},
    );
  }

  /// POST /games/{id}/comments/like
  Future<void> likeComment(String gameId, String commentId) async {
    await _api.post('/games/$gameId/comments/$commentId/like');
  }
}

final gameCommentsRepositoryProvider =
    Provider<GameCommentsRepository>((ref) => GameCommentsRepository());

final gameCommentsProvider =
    FutureProvider.family<List<GameComment>, String>((ref, gameId) async {
  return ref.read(gameCommentsRepositoryProvider).getComments(gameId);
});

/// 游戏评论模型
class GameComment {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String userLevel;
  final String content;
  final int likesCount;
  final bool isLiked;
  final DateTime? createdAt;
  final int replyCount;

  const GameComment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.userLevel,
    required this.content,
    required this.likesCount,
    required this.isLiked,
    this.createdAt,
    required this.replyCount,
  });

  factory GameComment.fromJson(Map<String, dynamic> json) {
    final user = json['_user'] is Map
        ? json['_user'] as Map<String, dynamic>
        : (json['user'] is Map
            ? json['user'] as Map<String, dynamic>
            : <String, dynamic>{});
    return GameComment(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      userId: user['_id']?.toString() ?? user['id']?.toString() ?? '',
      userName: user['name']?.toString() ?? '',
      userAvatar: _avatarUrl(user),
      userLevel: user['level']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      likesCount: (json['totalLikes'] is int)
          ? json['totalLikes'] as int
          : (json['likesCount'] is int ? json['likesCount'] as int : 0),
      isLiked: json['isLiked'] == true || json['liked'] == true,
      createdAt: json['created_at'] is String
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      replyCount: (json['totalComments'] is int)
          ? json['totalComments'] as int
          : (json['replyCount'] is int ? json['replyCount'] as int : 0),
    );
  }

  static String _avatarUrl(Map<String, dynamic> user) {
    final avatar = user['avatar'];
    if (avatar is String) return avatar;
    if (avatar is Map) {
      final fs = avatar['fileServer']?.toString() ?? '';
      final p = avatar['path']?.toString() ?? '';
      return fs.isEmpty ? p : '$fs$p';
    }
    return '';
  }
}

/// 游戏评论区 Widget
class GameCommentsSection extends ConsumerStatefulWidget {
  final String gameId;
  const GameCommentsSection({super.key, required this.gameId});

  @override
  ConsumerState<GameCommentsSection> createState() =>
      _GameCommentsSectionState();
}

class _GameCommentsSectionState extends ConsumerState<GameCommentsSection> {
  final _input = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final content = _input.text.trim();
    if (content.isEmpty) return;
    setState(() => _sending = true);
    try {
      await ref.read(gameCommentsRepositoryProvider).sendComment(
            widget.gameId,
            content,
          );
      _input.clear();
      if (!mounted) return;
      ref.invalidate(gameCommentsProvider(widget.gameId));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('发送失败: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(gameCommentsProvider(widget.gameId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '评论',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        async.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text('评论加载失败: $e',
                style: TextStyle(color: AppColors.secondaryText)),
          ),
          data: (list) {
            if (list.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  '还没有评论，来抢沙发吧',
                  style: TextStyle(color: AppColors.secondaryText),
                ),
              );
            }
            return Column(
              children: list
                  .map((c) => _CommentTile(
                        comment: c,
                        onLike: () async {
                          try {
                            await ref
                                .read(gameCommentsRepositoryProvider)
                                .likeComment(widget.gameId, c.id);
                            ref.invalidate(
                                gameCommentsProvider(widget.gameId));
                          } catch (_) {}
                        },
                      ))
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _input,
                maxLines: 1,
                decoration: const InputDecoration(
                  hintText: '说点什么...',
                  isDense: true,
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _sending ? null : _send,
              child: _sending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('发送'),
            ),
          ],
        ),
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  final GameComment comment;
  final VoidCallback onLike;
  const _CommentTile({required this.comment, required this.onLike});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipOval(
            child: SizedBox(
              width: 36,
              height: 36,
              child: comment.userAvatar.isEmpty
                  ? Container(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      child: const Icon(Icons.person, size: 20),
                    )
                  : CachedImage(
                      imageUrl: comment.userAvatar, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.userName,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    if (comment.userLevel.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          'Lv.${comment.userLevel}',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment.content,
                    style: const TextStyle(fontSize: 13, height: 1.4)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _formatTime(comment.createdAt),
                      style: TextStyle(
                          fontSize: 11, color: AppColors.secondaryText),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: onLike,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              comment.isLiked
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 14,
                              color: comment.isLiked
                                  ? Colors.red
                                  : AppColors.secondaryText,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              comment.likesCount.toString(),
                              style: TextStyle(
                                fontSize: 11,
                                color: comment.isLiked
                                    ? Colors.red
                                    : AppColors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime? t) {
    if (t == null) return '';
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
    if (diff.inDays < 1) return '${diff.inHours}小时前';
    if (diff.inDays < 30) return '${diff.inDays}天前';
    return '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
  }
}
