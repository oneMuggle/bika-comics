import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../shared/constants/api_constants.dart';
import '../domain/comic_model.dart';
import '../domain/comment_model.dart';

/// 漫画操作 Repository
class ComicRepository {
  final Dio _api = ApiClient.instance;

  /// 收藏漫画
  Future<void> favourite(String comicId) async {
    await _api.post(ApiEndpoints.favorite.replaceFirst('{id}', comicId));
  }

  /// 取消收藏
  Future<void> unfavourite(String comicId) async {
    await _api.delete(
      ApiEndpoints.favorite.replaceFirst('{id}', comicId),
      data: {},
    );
  }

  /// 追漫
  Future<void> follow(String comicId) async {
    await _api.post(ApiEndpoints.follow.replaceFirst('{id}', comicId));
  }

  /// 取消追漫
  Future<void> unfollow(String comicId) async {
    await _api.delete(
      ApiEndpoints.follow.replaceFirst('{id}', comicId),
      data: {},
    );
  }

  /// 点赞漫画
  Future<void> like(String comicId) async {
    await _api.post(ApiEndpoints.like.replaceFirst('{id}', comicId));
  }

  /// 获取我的收藏列表
  Future<List<Comic>> getMyFavourites({int page = 1}) async {
    final response = await _api.get(
      ApiEndpoints.myFavorites,
      queryParameters: {'s': 'da', 'page': page},
    );
    final data = response.data['data'];
    final comics = (data['comics'] as List)
        .map((json) => Comic.fromJson(json))
        .toList();
    return comics;
  }

  /// 获取我的追漫列表
  Future<List<Comic>> getMyFollows({int page = 1}) async {
    final response = await _api.get(
      ApiEndpoints.myFollows,
      queryParameters: {'s': 'dd', 'page': page},
    );
    final data = response.data['data'];
    final comics = (data['comics'] as List)
        .map((json) => Comic.fromJson(json))
        .toList();
    return comics;
  }

  // ================== 评论系统 ==================

  /// 获取漫画评论
  Future<List<Comment>> getComments(String comicId, {int page = 1}) async {
    final url =
        ApiEndpoints.comments.replaceFirst('{id}', comicId) + '?page=$page';
    final response = await _api.get(url);
    final data = response.data['data'];
    final docs = data['docs'] as List? ?? [];
    return docs.map((c) => Comment.fromJson(c as Map<String, dynamic>)).toList();
  }

  /// 发送评论
  Future<void> sendComment(String comicId, String content,
      {String? parentId}) async {
    final url = ApiEndpoints.sendComment.replaceFirst('{id}', comicId);
    await _api.post(
      url,
      data: {
        'content': content,
        if (parentId != null) 'parent': parentId,
      },
    );
  }

  /// 点赞评论 (POST /comments/{id}/like)
  Future<void> likeComment(String commentId) async {
    await _api.post('/comments/$commentId/like');
  }

  /// 获取子评论
  Future<List<Comment>> getCommentChildren(String commentId, {int page = 1}) async {
    final url = '/comments/$commentId/childrens?page=$page';
    final response = await _api.get(url);
    final data = response.data['data'];
    final docs = data['docs'] as List? ?? [];
    return docs.map((c) => Comment.fromJson(c as Map<String, dynamic>)).toList();
  }

  /// 发送子评论
  Future<void> sendCommentChild(String commentId, String content) async {
    await _api.post('/comments/$commentId', data: {'content': content});
  }

  /// 举报评论 (POST /comments/{id}/report)
  Future<void> reportComment(String commentId, {String reason = 'spam'}) async {
    await _api.post(
      '/comments/$commentId/report',
      data: {'reason': reason},
    );
  }

  // ================== 搜索热词 ==================

  /// 获取搜索热词列表 (GET /keywords)
  Future<List<String>> getKeywords() async {
    final response = await _api.get(ApiEndpoints.keywords);
    final data = response.data['data'];
    final list = data['keywords'] as List? ?? [];
    return list.map((e) => e.toString()).toList();
  }

  // ================== 漫画推荐 ==================

  /// 获取相关漫画推荐 (GET /comics/{id}/recommendation)
  Future<List<Comic>> getComicRecommendation(String comicId) async {
    final url =
        ApiEndpoints.comicRecommendation.replaceFirst('{id}', comicId);
    final response = await _api.get(url);
    final data = response.data['data'];
    final list = data['comics'] as List? ?? [];
    return list
        .map((json) => Comic.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}

/// Provider
final comicRepositoryProvider = Provider<ComicRepository>((ref) {
  return ComicRepository();
});
