import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/storage/secure_storage.dart';
import '../domain/chat_model.dart';

/// 聊天室仓库
///
/// 对应桌面端 `view/chat_new/chat_new_view.py` + `view/chat_new/chat_new_websocket.py`
/// - 桌面端 `GetNewChatLoginReq` POST `{NewChatUrl}auth/signin` body={email, password}
/// - 桌面端 `GetNewChatProfileReq` GET `{NewChatUrl}user/profile`
/// - 桌面端 `GetNewChatReq` GET `{NewChatUrl}room/list`
/// - 桌面端 `SendNewChatMsgReq` POST `{NewChatUrl}message/send-message`
///   body={roomId, message, referenceId, userMentions, replyId?}
///
/// WebSocket 路径（桌面端 ChatNewWebSocket.Start）：
///   `{NewChatUrl}` 替换 https→wss：http→ws，附加 `?token={token}&room={roomId}`
///   桌面端 ping_interval=30
class ChatRepository {
  // 桌面端 NewChatUrl = "https://live-server.bidobido.xyz/"
  static const String _chatBaseUrl = 'https://live-server.bidobido.xyz/';

  // 聊天 token 与主 API token 分开保存
  static const String _kChatToken = 'chat_token';

  // 缓存 token，避免每次开关都重登录
  String? _cachedToken;
  ChatProfile? _cachedProfile;

  String? get cachedToken => _cachedToken;
  ChatProfile? get cachedProfile => _cachedProfile;

  Future<String?> _loadCachedToken() async {
    if (_cachedToken != null) return _cachedToken;
    _cachedToken = await SecureStorageHolder.instance.read(_kChatToken);
    return _cachedToken;
  }

  Future<void> _saveToken(String token) async {
    _cachedToken = token;
    await SecureStorageHolder.instance.write(_kChatToken, token);
  }

  void clearToken() {
    _cachedToken = null;
    _cachedProfile = null;
    SecureStorageHolder.instance.delete(_kChatToken);
  }

  Dio _dio() {
    return Dio(BaseOptions(
      baseUrl: _chatBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ));
  }

  /// 登录聊天服务器，获取 token
  Future<String> login(String email, String password) async {
    final response = await _dio().post(
      'auth/signin',
      data: {'email': email, 'password': password},
    );
    final data = response.data is Map
        ? (response.data as Map).cast<String, dynamic>()
        : <String, dynamic>{};
    final token = data['token']?.toString();
    if (token == null || token.isEmpty) {
      throw Exception('登录聊天服务器失败：未返回 token');
    }
    await _saveToken(token);
    return token;
  }

  /// 获取用户 profile
  Future<ChatProfile> getProfile() async {
    final token = await _loadCachedToken();
    if (token == null) throw Exception('未登录聊天服务器');
    final response = await _dio().get(
      'user/profile',
      options: Options(headers: {'authorization': 'Bearer $token'}),
    );
    final data = response.data is Map
        ? (response.data as Map).cast<String, dynamic>()
        : <String, dynamic>{};
    final profile = data['profile'] is Map
        ? ChatProfile.fromJson((data['profile'] as Map).cast<String, dynamic>())
        : null;
    if (profile == null) throw Exception('获取聊天 Profile 失败');
    _cachedProfile = profile;
    return profile;
  }

  /// 获取房间列表
  Future<List<ChatRoom>> getRooms() async {
    final token = await _loadCachedToken();
    if (token == null) throw Exception('未登录聊天服务器');
    final response = await _dio().get(
      'room/list',
      options: Options(headers: {'authorization': 'Bearer $token'}),
    );
    final data = response.data is Map
        ? (response.data as Map).cast<String, dynamic>()
        : <String, dynamic>{};
    final rooms = (data['rooms'] as List? ?? [])
        .map((e) => ChatRoom.fromJson(e as Map<String, dynamic>))
        .toList();
    return rooms;
  }

  /// 发送文字消息
  Future<void> sendText({
    required String roomId,
    required String message,
    String? replyId,
  }) async {
    final token = await _loadCachedToken();
    if (token == null) throw Exception('未登录聊天服务器');
    await _dio().post(
      'message/send-message',
      data: {
        'roomId': roomId,
        'message': message,
        'referenceId': _genUuid(),
        'userMentions': <String>[],
        if (replyId != null && replyId.isNotEmpty) 'replyId': replyId,
      },
      options: Options(headers: {'authorization': 'Bearer $token'}),
    );
  }

  /// 发送图片消息
  ///
  /// 对应桌面端 `SendNewChatImgMsgReq`（`/home/ubuntu/project/picacg-qt-temp/src/server/req.py` lines 794-812）
  /// 端点：POST `{chatBaseUrl}message/send-image`
  /// Multipart form fields:
  ///   - roomId (text)
  ///   - caption (text, optional)
  ///   - referenceId (text, uuid)
  ///   - userMentions (text, JSON-stringified array, default "[]")
  ///   - medias (file, the picked image)
  /// Headers: `authorization: Bearer <chat_token>`，**不设置** Content-Type（让 dio 写入 multipart boundary）
  ///
  /// 返回：服务器返回的 message id（字符串），失败时抛异常
  Future<String> sendImage({
    required String roomId,
    required String filePath,
    String? filename,
    String? caption,
  }) async {
    final token = await _loadCachedToken();
    if (token == null) throw Exception('未登录聊天服务器');
    final formData = FormData.fromMap({
      'roomId': roomId,
      'caption': caption ?? '',
      'referenceId': _genUuid(),
      'userMentions': '[]',
      'medias': await MultipartFile.fromFile(
        filePath,
        filename: filename ?? filePath.split('/').last,
      ),
    });
    final response = await _dio().post(
      'message/send-image',
      data: formData,
      options: Options(
        headers: {
          'authorization': 'Bearer $token',
          // 显式移除 content-type，让 dio 自动写入 multipart/form-data; boundary=...
        },
        contentType: 'multipart/form-data',
      ),
    );
    final data = response.data is Map
        ? (response.data as Map).cast<String, dynamic>()
        : <String, dynamic>{};
    final id = data['id']?.toString() ??
        data['messageId']?.toString() ??
        data['_id']?.toString() ??
        '';
    return id;
  }

  /// 打开 WebSocket 连接到指定房间
  /// 返回 (channel, stream) — stream 是 WebSocket 收到的 JSON 消息
  Future<({WebSocketChannel channel, Stream<dynamic> stream})> connect({
    required String roomId,
    String? tokenOverride,
  }) async {
    final token = tokenOverride ?? await _loadCachedToken();
    if (token == null) throw Exception('未登录聊天服务器');
    final wsUrl = _chatBaseUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
    final uri = Uri.parse('$wsUrl?token=$token&room=$roomId');
    final channel = WebSocketChannel.connect(uri);
    // stream 是经过 JSON 解码的 message 流
    final stream = channel.stream.map((raw) {
      try {
        return jsonDecode(raw.toString());
      } catch (_) {
        return raw;
      }
    });
    return (channel: channel, stream: stream);
  }

  String _genUuid() {
    // 桌面端使用 uuid1（基于时间+MAC）。移动端我们用时间戳+随机数模拟
    final now = DateTime.now().microsecondsSinceEpoch;
    final r = (now ^ now.hashCode) & 0x7fffffff;
    return '$now-$r';
  }
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository();
});
