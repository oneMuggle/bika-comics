import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/secure_storage.dart';
import '../domain/friend_post_model.dart';

/// 好友动态（锅贴）仓库
///
/// 对应桌面端 `view/fried/fried_view.py` + `view/fried/qt_fried_msg.py` + `server/req.py`
/// - 桌面端使用外部独立 API `https://post-api.wikawika.xyz`（与 picacg 主 API 不同源）
/// - 桌面端 `AppInfoReq` GET `/posts?offset=N`（注意：使用 offset 而非 page）
/// - 桌面端 `AppCommentInfoReq` GET `/posts/{id}/comments?offset=N`
/// - 桌面端 `AppSendCommentInfoReq` POST `/comments` body=`{content, postId}`
/// - 桌面端 `AppCommentLikeReq` PUT `/comments/{id}/like` body=`{postId}`
///
/// 桌面端 `Setting.UserId` / `Setting.Password`（base64）作为锅贴的「Referer token」。
/// 移动端用同样的 pica API token 即可，因为桌面端 AppInfoReq 的 `token` header 实际上
/// 用的就是 `Server().token`（即 pica API 登录返回的 token）。
class FriendRepository {
  static const String _baseUrl = 'https://post-api.wikawika.xyz';
  static const String _userAgent =
      'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36';

  Dio _dio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'User-Agent': _userAgent,
          'Content-Type': 'application/json',
        },
      ),
    );
    return dio;
  }

  /// 动态列表（GET /posts?offset=N）
  /// 桌面端 offset 是已加载条数（每页 10 条）
  Future<FriendPostPage> getPosts({int offset = 0, int limit = 10}) async {
    final token = await SecureStorageHolder.instance.getApiToken() ?? '';
    final response = await _dio().get(
      '/posts',
      queryParameters: {'offset': offset},
      options: Options(
        headers: {
          'Referer': '$_baseUrl/?token=$token',
          'token': token,
        },
      ),
    );
    return FriendPostPage.fromJson(
      response.data is Map ? response.data as Map<String, dynamic> : {},
    );
  }

  /// 评论列表（GET /posts/{id}/comments?offset=N）
  Future<List<FriendComment>> getComments(String postId,
      {int offset = 0}) async {
    final token = await SecureStorageHolder.instance.getApiToken() ?? '';
    final response = await _dio().get(
      '/posts/$postId/comments',
      queryParameters: {'offset': offset},
      options: Options(
        headers: {
          'Referer': '$_baseUrl/?token=$token',
          'token': token,
        },
      ),
    );
    final data = response.data is Map ? response.data as Map<String, dynamic> : {};
    final docs = (data['data'] is Map ? data['data']['comments'] : null) as List? ?? [];
    return docs
        .map((e) => FriendComment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 发送评论（POST /comments body={content, postId}）
  Future<void> sendComment(String postId, String content) async {
    final token = await SecureStorageHolder.instance.getApiToken() ?? '';
    await _dio().post(
      '/comments',
      data: {'content': content, 'postId': postId},
      options: Options(
        headers: {
          'Referer': '$_baseUrl/?token=$token',
          'token': token,
        },
      ),
    );
  }

  /// 评论点赞（PUT /comments/{id}/like body={postId}）
  Future<void> likeComment(String postId, String commentId) async {
    final token = await SecureStorageHolder.instance.getApiToken() ?? '';
    await _dio().put(
      '/comments/$commentId/like',
      data: {'postId': postId},
      options: Options(
        headers: {
          'Referer': '$_baseUrl/?token=$token',
          'token': token,
        },
      ),
    );
  }

  /// 单条动态（GET /posts/{id}）
  ///
  /// 第九批新增：详情页需要展示 post 本身（不只是评论）。
  /// 服务端 `/posts/{id}` 直接返回 post 字段（与列表内单条 schema 一致）。
  Future<FriendPost> getPost(String postId) async {
    final token = await SecureStorageHolder.instance.getApiToken() ?? '';
    final response = await _dio().get(
      '/posts/$postId',
      options: Options(
        headers: {
          'Referer': '$_baseUrl/?token=$token',
          'token': token,
        },
      ),
    );
    final data = response.data is Map
        ? response.data as Map<String, dynamic>
        : <String, dynamic>{};
    final inner = (data['data'] is Map)
        ? (data['data'] as Map).cast<String, dynamic>()
        : data;
    if (inner.isEmpty) {
      throw FormatException('Empty response for /posts/$postId');
    }
    return FriendPost.fromJson(inner);
  }

  /// 动态点赞（PUT /posts/{id}/like）
  ///
  /// 第九批新增：桌面端没实现 post like（只有 comment like），但是锅贴 API
  /// 服务端提供 `/posts/{id}/like` 端点。移动端在 detail 页面顺手补上，
  /// 完成后整体对齐「评论点赞 / 动态点赞」两套交互。
  Future<void> likePost(String postId) async {
    final token = await SecureStorageHolder.instance.getApiToken() ?? '';
    await _dio().put(
      '/posts/$postId/like',
      options: Options(
        headers: {
          'Referer': '$_baseUrl/?token=$token',
          'token': token,
        },
      ),
    );
  }
}

final friendRepositoryProvider = Provider<FriendRepository>((ref) {
  return FriendRepository();
});

/// 动态列表 Provider（按 offset 缓存）
final friendPostsProvider =
    FutureProvider.family<FriendPostPage, int>((ref, offset) async {
  return ref.read(friendRepositoryProvider).getPosts(offset: offset);
});

/// 单条动态 Provider（按 postId 缓存）
///
/// 第九批新增：详情页需要展示 post 自身。
final friendPostProvider =
    FutureProvider.family<FriendPost, String>((ref, postId) async {
  return ref.read(friendRepositoryProvider).getPost(postId);
});
