import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../shared/constants/api_constants.dart';
import '../../comic/domain/comment_model.dart';

/// 用户个人中心相关 API
class UserRepository {
  final Dio _api = ApiClient.instance;

  /// 获取"我的评论"列表 (GET /users/my-comments?page=N)
  Future<List<Comment>> getMyComments({int page = 1}) async {
    final response = await _api.get(
      ApiEndpoints.myComments,
      queryParameters: {'page': page},
    );
    final data = response.data['data'];
    final docs = (data is Map ? data['docs'] : null) as List? ?? [];
    return docs
        .map((c) => Comment.fromJson(c as Map<String, dynamic>))
        .toList();
  }
}

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});
