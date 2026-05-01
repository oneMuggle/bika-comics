import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../shared/constants/api_constants.dart';
import '../domain/comic_model.dart';

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
}

/// Provider
final comicRepositoryProvider = Provider<ComicRepository>((ref) {
  return ComicRepository();
});
