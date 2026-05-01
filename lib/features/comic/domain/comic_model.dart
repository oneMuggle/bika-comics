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
  });

  factory Comic.fromJson(Map<String, dynamic> json) {
    final authorData = json['author'];
    String authorName = '';
    if (authorData is String) {
      authorName = authorData;
    } else if (authorData is Map) {
      authorName = authorData['name'] ?? '';
    }

    return Comic(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      author: authorName,
      coverUrl: _parseCoverUrl(json),
      description: json['description'] ?? '',
      tags: _parseTags(json['tags']),
      totalViews: json['totalViews'] ?? json['views_count'] ?? 0,
      likeCount: json['likeCount'] ?? json['likes_count'] ?? 0,
      episodeCount: json['epsCount'] ?? json['eps_count'] ?? 0,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
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
  }) =>
      Comic(
        id: id ?? this.id,
        title: title ?? this.title,
        author: author ?? this.author,
        coverUrl: coverUrl ?? this.coverUrl,
        description: description ?? this.description,
        tags: tags ?? this.tags,
        totalViews: totalViews ?? this.totalViews,
        likeCount: likeCount ?? this.likeCount,
        episodeCount: episodeCount ?? this.episodeCount,
        updatedAt: updatedAt ?? this.updatedAt,
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
            ? DateTime.tryParse(json['published_at'])
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
