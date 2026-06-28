/// 骑士榜（Knight Rank）领域模型
///
/// 桌面端 API: GET /comics/knight-leaderboard
/// 响应结构: { "data": { "users": [ { _id, name, slogan, avatar, title, level, character } ] } }
library;

import 'package:flutter/foundation.dart';

/// 骑士榜用户头像
@immutable
class KnightAvatar {
  final String fileServer;
  final String path;

  const KnightAvatar({required this.fileServer, required this.path});

  /// 拼接后的完整 URL
  String get url => fileServer.isEmpty ? path : '$fileServer$path';

  factory KnightAvatar.fromJson(dynamic raw) {
    if (raw is String) {
      return KnightAvatar(fileServer: '', path: raw);
    }
    if (raw is Map<String, dynamic>) {
      return KnightAvatar(
        fileServer: raw['fileServer'] ?? '',
        path: raw['path'] ?? '',
      );
    }
    return const KnightAvatar(fileServer: '', path: '');
  }
}

/// 骑士榜用户
@immutable
class KnightUser {
  final String id;
  final String name;
  final String slogan;
  final String title;
  final int level;
  final String character;
  final KnightAvatar avatar;

  const KnightUser({
    required this.id,
    required this.name,
    required this.slogan,
    required this.title,
    required this.level,
    required this.character,
    required this.avatar,
  });

  factory KnightUser.fromJson(Map<String, dynamic> json) {
    return KnightUser(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      slogan: json['slogan'] ?? '',
      title: json['title'] ?? '',
      level: json['level'] is int
          ? json['level']
          : int.tryParse('${json['level']}') ?? 1,
      character: json['character'] ?? '',
      avatar: KnightAvatar.fromJson(json['avatar']),
    );
  }

  bool get hasAvatar => avatar.url.isNotEmpty;
}

/// 骑士榜响应
@immutable
class KnightRank {
  final List<KnightUser> users;

  const KnightRank({required this.users});

  factory KnightRank.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final list = (data is Map<String, dynamic> && data['users'] is List)
        ? (data['users'] as List)
            .whereType<Map<String, dynamic>>()
            .map(KnightUser.fromJson)
            .toList()
        : <KnightUser>[];
    return KnightRank(users: list);
  }
}
