import 'package:flutter/foundation.dart';

/// 好友动态（锅贴）作者信息
@immutable
class FriendPostUser {
  final String id;
  final String name;
  final String avatar;
  final String title;
  final int level;
  final String character;

  const FriendPostUser({
    required this.id,
    required this.name,
    required this.avatar,
    required this.title,
    required this.level,
    required this.character,
  });

  factory FriendPostUser.fromJson(Map<String, dynamic> json) {
    return FriendPostUser(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      avatar: json['avatar']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      level: json['level'] is int ? json['level'] as int : 0,
      character: json['character']?.toString() ?? '',
    );
  }
}

/// 单条动态
@immutable
class FriendPost {
  final String id;
  final String content;
  final FriendPostUser user;
  final List<String> medias;
  final int totalLikes;
  final int totalComments;
  final bool liked;
  final DateTime? createdAt;

  const FriendPost({
    required this.id,
    required this.content,
    required this.user,
    this.medias = const [],
    this.totalLikes = 0,
    this.totalComments = 0,
    this.liked = false,
    this.createdAt,
  });

  factory FriendPost.fromJson(Map<String, dynamic> json) {
    final user = json['_user'] is Map
        ? FriendPostUser.fromJson(
            (json['_user'] as Map).cast<String, dynamic>(),
          )
        : const FriendPostUser(
            id: '',
            name: '',
            avatar: '',
            title: '',
            level: 0,
            character: '',
          );
    return FriendPost(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      user: user,
      medias: (json['medias'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      totalLikes: json['totalLikes'] is int ? json['totalLikes'] as int : 0,
      totalComments:
          json['totalComments'] is int ? json['totalComments'] as int : 0,
      liked: json['liked'] == true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}

/// 分页结果
@immutable
class FriendPostPage {
  final List<FriendPost> posts;
  final int total;
  final int limit;

  const FriendPostPage({
    this.posts = const [],
    this.total = 0,
    this.limit = 10,
  });

  factory FriendPostPage.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] is Map) ? json['data'] as Map : null;
    if (data == null) return const FriendPostPage();
    final posts = (data['posts'] as List? ?? [])
        .map((e) => FriendPost.fromJson(e as Map<String, dynamic>))
        .toList();
    final total = (data['total'] is int) ? data['total'] as int : posts.length;
    final limit = (data['limit'] is int) ? data['limit'] as int : 10;
    return FriendPostPage(posts: posts, total: total, limit: limit);
  }
}

/// 锅贴评论
@immutable
class FriendComment {
  final String id;
  final String content;
  final FriendPostUser user;
  final int totalLikes;
  final bool liked;
  final DateTime? createdAt;

  const FriendComment({
    required this.id,
    required this.content,
    required this.user,
    this.totalLikes = 0,
    this.liked = false,
    this.createdAt,
  });

  factory FriendComment.fromJson(Map<String, dynamic> json) {
    final user = json['_user'] is Map
        ? FriendPostUser.fromJson(
            (json['_user'] as Map).cast<String, dynamic>(),
          )
        : const FriendPostUser(
            id: '',
            name: '',
            avatar: '',
            title: '',
            level: 0,
            character: '',
          );
    return FriendComment(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      user: user,
      totalLikes: json['totalLikes'] is int ? json['totalLikes'] as int : 0,
      liked: json['liked'] == true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}
