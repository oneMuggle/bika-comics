/// Pica 号（推荐位）解析服务
///
/// 桌面端: `req.GetShareIdReq`, `req.GetIdByShareIdReq`, `req.GetRecommendByIdReq`
/// 桌面端代码: src/server/req.py
///
/// 实际接口位于独立域名: https://recommend.go2778.com
/// - GET /pic/share/get/?shareId=<pica号>  → 解析回漫画 ID
/// - GET /pic/share/set/?c=<bookId>        → 生成 Pica 号
/// - GET /pic/recommend/get/?c=<bookId>    → 推荐位内容

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/constants/api_constants.dart';

class PicaShareService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    responseType: ResponseType.json,
  ));

  /// 通过 Pica 号 (shareId) 解析回漫画 ID
  ///
  /// 对应桌面端 `GetIdByShareIdReq`
  Future<String?> resolveShareId(String shareId) async {
    try {
      final resp = await _dio.get(
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
    } on DioException {
      return null;
    }
  }

  /// 将漫画 ID 编码成 Pica 号
  ///
  /// 对应桌面端 `GetShareIdReq`
  Future<String?> generateShareId(String bookId) async {
    try {
      final resp = await _dio.get(
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
    } on DioException {
      return null;
    }
  }

  /// 获取漫画的推荐位
  ///
  /// 对应桌面端 `GetRecommendByIdReq`
  Future<List<String>> getRecommendations(String bookId) async {
    try {
      final resp = await _dio.get(
        ApiEndpoints.picaRecommendGet,
        queryParameters: {'c': bookId},
      );
      final data = resp.data;
      if (data is Map<String, dynamic> && data['data'] is List) {
        return (data['data'] as List)
            .whereType<String>()
            .toList(growable: false);
      }
      return const [];
    } on DioException {
      return const [];
    }
  }
}

final picaShareServiceProvider = Provider<PicaShareService>((ref) {
  return PicaShareService();
});
