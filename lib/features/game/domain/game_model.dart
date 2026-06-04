/// 游戏（Games）领域模型
///
/// 桌面端 API:
///   GET /games?page=N          — 游戏列表
///   GET /games/{id}            — 游戏详情
///   GET /games/{id}/comments   — 游戏评论
///
/// 对应桌面端代码:
///   src/view/game/game_view.py        — 游戏列表
///   src/view/info/game_info_view.py   — 游戏详情
///   src/server/req.py -> GetGameReq / GetGameInfoReq / GetGameCommentsReq
library;

import 'package:flutter/foundation.dart';

/// 游戏图标（封面）
@immutable
class GameIcon {
  final String fileServer;
  final String path;

  const GameIcon({required this.fileServer, required this.path});

  /// 拼接后的完整 URL
  String get url => fileServer.isEmpty ? path : '$fileServer$path';

  factory GameIcon.fromJson(dynamic raw) {
    if (raw is String) {
      return GameIcon(fileServer: '', path: raw);
    }
    if (raw is Map) {
      return GameIcon(
        fileServer: raw['fileServer']?.toString() ?? '',
        path: raw['path']?.toString() ?? '',
      );
    }
    return const GameIcon(fileServer: '', path: '');
  }
}

/// 游戏模型（列表项 / 详情共用）
@immutable
class Game {
  final String id;
  final String title;
  final String description;
  final String version;
  final String size;
  final String publisher;
  final GameIcon icon;
  final List<String> androidLinks;
  final List<String> iosLinks;
  final List<GameIcon> screenshots;
  final DateTime? updatedAt;
  final bool adult;
  final bool suggest;
  final bool android;
  final bool ios;
  final int? likesCount;
  final int? commentsCount;

  const Game({
    required this.id,
    required this.title,
    required this.description,
    required this.version,
    required this.size,
    required this.publisher,
    required this.icon,
    required this.androidLinks,
    required this.iosLinks,
    required this.screenshots,
    this.updatedAt,
    this.adult = false,
    this.suggest = false,
    this.android = false,
    this.ios = false,
    this.likesCount,
    this.commentsCount,
  });

  /// 列表项构造：来自 `data.games.docs[]`
  factory Game.fromListJson(Map<String, dynamic> json) {
    return Game(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      version: json['version']?.toString() ?? '',
      size: json['size']?.toString() ?? '',
      publisher: json['publisher']?.toString() ?? '',
      icon: GameIcon.fromJson(json['icon']),
      androidLinks: _parseStringList(json['androidLinks']),
      iosLinks: _parseStringList(json['iosLinks']),
      screenshots: _parseScreenshots(json['screenshots']),
      updatedAt: _parseDate(json['updated_at']),
      adult: json['adult'] == true,
      suggest: json['suggest'] == true,
      android: json['android'] == true,
      ios: json['ios'] == true,
      likesCount: json['likesCount'] is int ? json['likesCount'] : null,
      commentsCount: json['commentsCount'] is int ? json['commentsCount'] : null,
    );
  }

  /// 详情构造：来自 `data.game`
  factory Game.fromDetailJson(Map<String, dynamic> json) {
    return Game(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      version: json['version']?.toString() ?? '',
      size: json['size']?.toString() ?? '',
      publisher: json['publisher']?.toString() ?? '',
      icon: GameIcon.fromJson(json['icon']),
      androidLinks: _parseStringList(json['androidLinks']),
      iosLinks: _parseStringList(json['iosLinks']),
      screenshots: _parseScreenshots(json['screenshots']),
      updatedAt: _parseDate(json['updated_at']),
      adult: json['adult'] == true,
      suggest: json['suggest'] == true,
      android: json['android'] == true,
      ios: json['ios'] == true,
      likesCount: json['likesCount'] is int ? json['likesCount'] : null,
      commentsCount: json['commentsCount'] is int ? json['commentsCount'] : null,
    );
  }

  static List<String> _parseStringList(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
    }
    return const [];
  }

  static List<GameIcon> _parseScreenshots(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((m) => GameIcon.fromJson(m))
          .where((g) => g.url.isNotEmpty)
          .toList();
    }
    return const [];
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw is String && raw.isNotEmpty) {
      return DateTime.tryParse(raw);
    }
    return null;
  }
}

/// 游戏列表分页响应
@immutable
class GameListPage {
  final List<Game> games;
  final int page;
  final int pages;
  final int total;

  const GameListPage({
    required this.games,
    required this.page,
    required this.pages,
    required this.total,
  });

  factory GameListPage.fromJson(Map<String, dynamic> json) {
    final gamesNode = (json['games'] is Map) ? json['games'] as Map : json;
    final docs = (gamesNode['docs'] is List)
        ? gamesNode['docs'] as List
        : const [];
    final games = docs
        .whereType<Map>()
        .map((m) => Game.fromListJson(Map<String, dynamic>.from(m)))
        .toList();
    return GameListPage(
      games: games,
      page: (gamesNode['page'] is int) ? gamesNode['page'] as int : 1,
      pages: (gamesNode['pages'] is int) ? gamesNode['pages'] as int : 1,
      total: (gamesNode['total'] is int) ? gamesNode['total'] as int : games.length,
    );
  }
}
