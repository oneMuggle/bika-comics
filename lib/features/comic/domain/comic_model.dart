import 'package:flutter/foundation.dart';

/// 漫画模型
@immutable
class Comic {
  final String id;
  final String title;
  final String author;
  final String coverUrl;
  final String description;
  final List<String> tags;
  final int totalViews;
  final int likeCount;
  final int episodeCount;
  final DateTime? updatedAt;
  final bool isLiked;
  final bool isFollowed;
  final bool isFavorite;
  bool get isFavourite => isFavorite;

  // ===== 第十五批新增字段 — 对齐桌面端 Book 模型 =====

  /// 上传者（creator / uploader），桌面端显示为单独一行
  final String creator;

  /// 汉化组（chineseTeam），与 author 区别
  final String chineseTeam;

  /// 总页数（pagesCount）— 用于详情页 / 阅读器顶部展示
  final int pagesCount;

  /// 是否完结（finished）
  final bool finished;

  /// 分享 ID — 用于生成 `pica+id` 分享链接 / 通过 Pica 号反查漫画
  final String shareId;

  /// 创建时间（created_at）
  final DateTime? createdAt;

  const Comic({
    required this.id,
    required this.title,
    required this.author,
    required this.coverUrl,
    required this.description,
    required this.tags,
    required this.totalViews,
    required this.likeCount,
    required this.episodeCount,
    this.updatedAt,
    this.isLiked = false,
    this.isFollowed = false,
    this.isFavorite = false,
    // 新字段默认值
    this.creator = '',
    this.chineseTeam = '',
    this.pagesCount = 0,
    this.finished = false,
    this.shareId = '',
    this.createdAt,
  });

  factory Comic.fromJson(Map<String, dynamic> json) {
    final authorData = json['author'];
    String authorName = '';
    if (authorData is String) {
      authorName = authorData;
    } else if (authorData is Map) {
      authorName = authorData['name'] ?? '';
    }

    // creator 字段可能是 String 或 Map {name, ...}
    final creatorData = json['creator'];
    String creatorName = '';
    if (creatorData is String) {
      creatorName = creatorData;
    } else if (creatorData is Map) {
      creatorName = creatorData['name'] ?? '';
    }

    // chineseTeam 字段类型：String（汉化组名）
    final chineseTeamData = json['chineseTeam'];
    String chineseTeamName = '';
    if (chineseTeamData is String) {
      chineseTeamName = chineseTeamData;
    }

    return Comic(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      author: authorName,
      creator: creatorName,
      chineseTeam: chineseTeamName,
      coverUrl: _parseCoverUrl(json),
      description: json['description'] ?? '',
      tags: _parseTags(json['tags']),
      totalViews: json['totalViews'] ?? json['views_count'] ?? 0,
      likeCount: json['likeCount'] ?? json['likes_count'] ?? 0,
      episodeCount: json['epsCount'] ?? json['eps_count'] ?? 0,
      pagesCount: json['pagesCount'] ?? json['pages_count'] ?? 0,
      finished: json['finished'] ?? false,
      shareId: json['shareId']?.toString() ?? '',
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      isLiked: json['isLiked'] ?? false,
      isFollowed: json['isFollowed'] ?? false,
      isFavorite: json['isFavourite'] ?? false,
    );
  }

  static String _parseCoverUrl(Map<String, dynamic> json) {
    final cover = json['cover'];
    if (cover == null) return '';
    if (cover is String) return cover;
    if (cover is Map) {
      return cover['path'] ?? cover['url'] ?? '';
    }
    return '';
  }

  static List<String> _parseTags(dynamic tags) {
    if (tags == null) return [];
    if (tags is List) return tags.map((t) => t.toString()).toList();
    return [];
  }

  Comic copyWith({
    String? id,
    String? title,
    String? author,
    String? coverUrl,
    String? description,
    List<String>? tags,
    int? totalViews,
    int? likeCount,
    int? episodeCount,
    DateTime? updatedAt,
    bool? isLiked,
    bool? isFollowed,
    bool? isFavorite,
    String? creator,
    String? chineseTeam,
    int? pagesCount,
    bool? finished,
    String? shareId,
    DateTime? createdAt,
  }) =>
      Comic(
        id: id ?? this.id,
        title: title ?? this.title,
        author: author ?? this.author,
        creator: creator ?? this.creator,
        chineseTeam: chineseTeam ?? this.chineseTeam,
        coverUrl: coverUrl ?? this.coverUrl,
        description: description ?? this.description,
        tags: tags ?? this.tags,
        totalViews: totalViews ?? this.totalViews,
        likeCount: likeCount ?? this.likeCount,
        episodeCount: episodeCount ?? this.episodeCount,
        pagesCount: pagesCount ?? this.pagesCount,
        finished: finished ?? this.finished,
        shareId: shareId ?? this.shareId,
        updatedAt: updatedAt ?? this.updatedAt,
        createdAt: createdAt ?? this.createdAt,
        isLiked: isLiked ?? this.isLiked,
        isFollowed: isFollowed ?? this.isFollowed,
        isFavorite: isFavorite ?? this.isFavorite,
      );
}

/// 章节模型
@immutable
class Episode {
  final String id;
  final String title;
  final int order;
  final DateTime? publishedAt;

  const Episode({
    required this.id,
    required this.title,
    required this.order,
    this.publishedAt,
  });

  factory Episode.fromJson(Map<String, dynamic> json) => Episode(
        id: json['_id'] ?? json['id'] ?? '',
        title: json['title'] ?? '',
        order: json['order'] ?? 0,
        publishedAt: json['published_at'] != null
            ? DateTime.tryParse(json['published_at'].toString())
            : null,
      );
}

/// 漫画详情
@immutable
class ComicDetail {
  final Comic comic;
  final List<Episode> episodes;

  const ComicDetail({required this.comic, required this.episodes});
}