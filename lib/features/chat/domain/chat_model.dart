import 'package:flutter/foundation.dart';

/// 聊天室
@immutable
class ChatRoom {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int minLevel;
  final int minRegisterDays;
  final bool isPublic;
  final bool isAvailable;

  const ChatRoom({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.minLevel,
    required this.minRegisterDays,
    required this.isPublic,
    required this.isAvailable,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      icon: json['icon']?.toString() ?? '',
      minLevel: json['minLevel'] is int ? json['minLevel'] as int : 0,
      minRegisterDays:
          json['minRegisterDays'] is int ? json['minRegisterDays'] as int : 0,
      isPublic: json['isPublic'] == true,
      isAvailable: json['isAvailable'] == true,
    );
  }
}

/// 用户 Profile（聊天服务器）
@immutable
class ChatProfile {
  final String id;
  final String name;
  final String avatarUrl;
  final int level;
  final String title;
  final List<String> characters;

  const ChatProfile({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.level,
    required this.title,
    required this.characters,
  });

  factory ChatProfile.fromJson(Map<String, dynamic> json) {
    return ChatProfile(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString() ?? '',
      level: json['level'] is int ? json['level'] as int : 0,
      title: json['title']?.toString() ?? '',
      characters: (json['characters'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
    );
  }
}

/// 聊天消息
@immutable
class ChatMessage {
  final String id;
  final String referenceId;
  final String type; // TEXT_MESSAGE | IMAGE_MESSAGE | CONNECTED | INITIAL_MESSAGES | ...
  final DateTime? createdAt;
  final String? text;
  final String? imageUrl;
  final String? caption;
  final ChatProfile? profile;
  final String platform;
  final int? onlineCount;
  final ChatMessageReply? reply;

  const ChatMessage({
    required this.id,
    required this.referenceId,
    required this.type,
    this.createdAt,
    this.text,
    this.imageUrl,
    this.caption,
    this.profile,
    this.platform = '',
    this.onlineCount,
    this.reply,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] is Map) ? (json['data'] as Map).cast<String, dynamic>() : <String, dynamic>{};
    final profile = data['profile'] is Map
        ? ChatProfile.fromJson((data['profile'] as Map).cast<String, dynamic>())
        : null;
    final replyData = data['reply'] is Map
        ? (data['reply'] as Map).cast<String, dynamic>()
        : null;
    final reply = replyData != null ? ChatMessageReply.fromJson(replyData) : null;
    String? text;
    String? imageUrl;
    String? caption;
    if (json['type'] == 'TEXT_MESSAGE') {
      text = data['message']?.toString() ?? '';
    } else if (json['type'] == 'IMAGE_MESSAGE') {
      caption = data['caption']?.toString() ?? '';
      final medias = data['medias'] as List?;
      if (medias != null && medias.isNotEmpty) {
        imageUrl = medias.first.toString();
      }
    } else if (json['type'] == 'INITIAL_MESSAGES') {
      // 历史消息包装在 data.messages[]
    }
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      referenceId: json['referenceId']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      text: text,
      imageUrl: imageUrl,
      caption: caption,
      profile: profile,
      platform: data['platform']?.toString() ?? '',
      onlineCount: data['onlineCount'] is int ? data['onlineCount'] as int : null,
      reply: reply,
    );
  }
}

@immutable
class ChatMessageReply {
  final String id;
  final String type;
  final String? message;
  final String? name;
  final String? media;

  const ChatMessageReply({
    required this.id,
    required this.type,
    this.message,
    this.name,
    this.media,
  });

  factory ChatMessageReply.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] is Map)
        ? (json['data'] as Map).cast<String, dynamic>()
        : <String, dynamic>{};
    return ChatMessageReply(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      message: data['message']?.toString(),
      name: data['name']?.toString(),
      media: data['media']?.toString(),
    );
  }
}
