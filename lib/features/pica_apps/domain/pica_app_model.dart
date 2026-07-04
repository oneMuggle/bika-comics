/// Pica Apps 领域模型
///
/// 桌面端 API: GET /pica-apps
/// 对应桌面端代码:
///   src/server/req.py -> GetAPPsReq   (响应 isParseRes=False,直接返回 JSON 列表)
///   src/server/res.py  -> AppsHandler  (返回 [{title, icon, url}, ...])
///
/// Pica Apps 是 Pica 官方在主站里推荐的第三方客户端/工具入口,
/// 响应是一个 list 而不是分页结构 — 每项包含 name/icon/downloadUrl/platform 等。
library;

import 'package:flutter/foundation.dart';

/// Pica App 图标
@immutable
class PicaAppIcon {
  final String fileServer;
  final String path;

  const PicaAppIcon({required this.fileServer, required this.path});

  /// 拼接后的完整 URL
  String get url => fileServer.isEmpty ? path : '$fileServer$path';

  factory PicaAppIcon.fromJson(dynamic raw) {
    if (raw is String) {
      return PicaAppIcon(fileServer: '', path: raw);
    }
    if (raw is Map) {
      return PicaAppIcon(
        fileServer: raw['fileServer']?.toString() ?? '',
        path: raw['path']?.toString() ?? '',
      );
    }
    return const PicaAppIcon(fileServer: '', path: '');
  }
}

/// 第三方应用/客户端模型
@immutable
class PicaApp {
  /// 唯一 ID — 后端可能返回 `_id` / `id` / `appId` 多种形式,统一收敛
  final String id;

  /// 显示名称
  final String title;

  /// 副标题 / 描述 (可选)
  final String description;

  /// 主下载/跳转 URL (app store / 应用市场 / 官网)
  final String url;

  /// 平台标识 — 'android' / 'ios' / 'web' / 空字符串 (通用)
  final String platform;

  /// 图标
  final PicaAppIcon icon;

  /// 发布时间(可选)
  final DateTime? updatedAt;

  /// 排序权重(可选,大者优先)
  final int? sort;

  const PicaApp({
    required this.id,
    required this.title,
    required this.description,
    required this.url,
    required this.platform,
    required this.icon,
    this.updatedAt,
    this.sort,
  });

  /// 解析一行 Pica App
  ///
  /// 兼容多种字段命名:
  /// - id:   `_id` / `id` / `appId`
  /// - 名称: `title` / `name` / `appName`
  /// - URL:  `url` / `downloadUrl` / `link` / `appUrl`
  /// - 平台: `platform` / `os` / `type`
  factory PicaApp.fromJson(Map<String, dynamic> json) {
    String pickString(List<String> keys, {String fallback = ''}) {
      for (final k in keys) {
        final v = json[k];
        if (v is String && v.isNotEmpty) return v;
      }
      return fallback;
    }

    final id = pickString(const ['_id', 'id', 'appId']);
    final title = pickString(const ['title', 'name', 'appName']);
    final url = pickString(const ['url', 'downloadUrl', 'link', 'appUrl']);

    final descriptionRaw = json['description'] ?? json['subTitle'] ?? json['summary'];
    final description = descriptionRaw is String ? descriptionRaw : '';

    final platformRaw = json['platform'] ?? json['os'] ?? json['type'];
    final platform = platformRaw is String ? platformRaw : '';

    final sortRaw = json['sort'] ?? json['order'] ?? json['weight'];
    final sort = sortRaw is int ? sortRaw : null;

    final dateRaw = json['updated_at'] ?? json['updatedAt'] ?? json['created_at'];

    return PicaApp(
      id: id,
      title: title,
      description: description,
      url: url,
      platform: platform,
      icon: PicaAppIcon.fromJson(json['icon'] ?? json['logo']),
      sort: sort,
      updatedAt: dateRaw is String && dateRaw.isNotEmpty
          ? DateTime.tryParse(dateRaw)
          : null,
    );
  }

  /// 是否可点击(必须有 title 和 url)
  bool get isClickable => title.isNotEmpty && url.isNotEmpty;
}
