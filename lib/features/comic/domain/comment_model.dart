/// 评论模型
class Comment {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String content;
  final int likeCount;
  final bool isLiked;
  final String createdAt;
  final String? parentId;
  final int replyCount;

  const Comment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.content,
    required this.likeCount,
    required this.isLiked,
    required this.createdAt,
    this.parentId,
    this.replyCount = 0,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    return Comment(
      id: json['_id'] ?? json['id'] ?? '',
      userId: user['_id'] ?? user['id'] ?? '',
      userName: user['name'] ?? user['username'] ?? '匿名',
      userAvatar: _parseAvatar(user['avatar']),
      content: json['content'] ?? '',
      likeCount: json['likeCount'] ?? 0,
      isLiked: json['isLiked'] ?? false,
      createdAt: json['created_at'] ?? json['createdAt'] ?? '',
      parentId: json['parent']?['_id'] ?? json['parentId'],
      replyCount: json['replyCount'] ?? 0,
    );
  }

  static String _parseAvatar(dynamic avatar) {
    if (avatar == null) return '';
    if (avatar is String) return avatar;
    if (avatar is Map) {
      return avatar['path'] ?? avatar['url'] ?? '';
    }
    return '';
  }
}
