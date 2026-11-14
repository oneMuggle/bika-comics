/// Pica 号（推荐位）解析服务
///
/// 桌面端: `req.GetShareIdReq`, `req.GetIdByShareIdReq`, `req.GetRecommendByIdReq`
/// 桌面端代码: src/server/req.py
///
/// 实际接口位于独立域名: https://recommend.go2778.com
/// - GET /pic/share/get/?shareId=<pica号>  → 解析回漫画 ID
/// - GET /pic/share/set/?c=<bookId>        → 生成 Pica 号
/// - GET /pic/recommend/get/?c=<bookId>    → 推荐位内容
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../shared/constants/api_constants.dart';

class PicaShareService {
  // 第五十九批：原本用裸 `Dio(BaseOptions(...))`，绕过代理配置。
  // 改用统一客户端，使代理开关对分享/推荐位请求同样生效。
  //
  // 第六十批：每次调用都新建一个 `Dio`，必须保证用完后关闭
  // （否则每次分享都会泄漏一个 HttpClient）。见 [ApiClient.withClient]。
  Dio _buildDio() => ApiClient.createClient(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      );

  /// 通过 Pica 号 (shareId) 解析回漫画 ID
  ///
  /// 对应桌面端 `GetIdByShareIdReq`
  Future<String?> resolveShareId(String shareId) async {
    try {
      return await ApiClient.withClient(
        _buildDio,
        action: (client) async {
          final resp = await client.get(
            ApiEndpoints.picaShareGet,
            queryParameters: {'shareId': shareId},
          );
          final data = resp.data is Map<String, dynamic>
              ? resp.data as Map<String, dynamic>
              : <String, dynamic>{};
          // 服务端实际返回结构: { code, data: { _id, ... } }
          final inner = data['data'];
          if (inner is Map<String, dynamic>) {
            return (inner['_id'] ?? inner['id']) as String?;
          }
          return null;
        },
      );
    } on DioException {
      return null;
    }
  }

  /// 将漫画 ID 编码成 Pica 号
  ///
  /// 对应桌面端 `GetShareIdReq`
  Future<String?> generateShareId(String bookId) async {
    try {
      return await ApiClient.withClient(
        _buildDio,
        action: (client) async {
          final resp = await client.get(
            ApiEndpoints.picaShareSet,
            queryParameters: {'c': bookId},
          );
          final data = resp.data;
          if (data is Map<String, dynamic>) {
            return (data['data']?['shareId'] ??
                    data['shareId'] ??
                    data['data']?['code']) as String?;
          }
          return null;
        },
      );
    } on DioException {
      return null;
    }
  }

  /// 获取漫画的推荐位
  ///
  /// 对应桌面端 `GetRecommendByIdReq`
  Future<List<String>> getRecommendations(String bookId) async {
    try {
      return await ApiClient.withClient(
        _buildDio,
        action: (client) async {
          final resp = await client.get(
            ApiEndpoints.picaRecommendGet,
            queryParameters: {'c': bookId},
          );
          final data = resp.data;
          if (data is Map<String, dynamic> && data['data'] is List) {
            return (data['data'] as List)
                .whereType<String>()
                .toList(growable: false);
          }
          return const <String>[];
        },
      );
    } on DioException {
      return const [];
    }
  }
}

final picaShareServiceProvider = Provider<PicaShareService>((ref) {
  return PicaShareService();
});
