import 'package:flutter/foundation.dart';

import '../../../core/utils/media_url.dart';

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
      // 桌面端 `book_info_view.py:354` 用 `ToolUtil.GetRealUrl(fileServer, path)`
      // 拼接。pica 返回的 `path` 是相对路径，必须与 `fileServer` 组合，
      // 否则 `CachedNetworkImage` 拿到相对路径无法加载。
      return mediaUrlFrom(cover);
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

/// 章节列表的一页（带分页元信息）
///
/// 第六十二批新增。对应 API 响应体的 `data.eps` 节点：
/// ```json
/// { "docs": [ ... ], "total": 389, "pages": 2, "limit": 200, "page": 1 }
/// ```
/// 桌面端 `src/tools/book.py:162-174` 读取同一组字段
/// （`total` -> `epsCount`，`pages` -> `maxLoadEps`，`limit` -> `epsLimit`）。
@immutable
class EpisodePage {
  /// 当前页的章节
  final List<Episode> episodes;

  /// 总章节数（`eps.total`）
  final int total;

  /// 总页数（`eps.pages`）
  final int pages;

  /// 每页条数（`eps.limit`）
  final int limit;

  /// 当前页号（`eps.page`）
  final int page;

  const EpisodePage({
    required this.episodes,
    this.total = 0,
    this.pages = 1,
    this.limit = 0,
    this.page = 1,
  });
}

/// 章节**图片**列表的一页（带分页元信息）
///
/// 第六十二批新增。对应 API 响应体的 `data.pages` 节点：
/// ```json
/// { "docs": [ ... ], "total": 4896, "pages": 25, "limit": 200, "page": 1 }
/// ```
///
/// 桌面端 `src/tools/book.py:221-241` 读取同一组字段：
///   `total` -> `epsInfo.maxPics`（该章节图片总数）
///   `pages` -> `epsInfo.maxPicPages`（图片分页组数）
///   `limit` -> `epsInfo.picLimit`（每组图片数）
///   `page`  -> `epsInfo.curLoadPicPages`
///
/// **为什么重要**：真实 API 抓取数据（150,574 条漫画记录）显示，
/// 有 6,354 部**单章**漫画的一个章节内图片数超过 200（即超过一页），
/// 最多的一章有 4,896 张图片 = 25 个分页组。
/// 移动端此前固定只请求 `?page=1`，这些章节只能看到前 200 张图。
@immutable
class ImagePage {
  /// 当前页的图片 URL 列表
  final List<String> urls;

  /// 该章节图片总数（`pages.total`）
  final int total;

  /// 总页数（`pages.pages`）
  final int pages;

  /// 每页条数（`pages.limit`）
  final int limit;

  /// 当前页号（`pages.page`）
  final int page;

  const ImagePage({
    required this.urls,
    this.total = 0,
    this.pages = 1,
    this.limit = 0,
    this.page = 1,
  });
}