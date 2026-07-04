import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../shared/constants/api_constants.dart';
import '../domain/pica_app_model.dart';

/// Pica 官方推荐的第三方应用/客户端列表
///
/// 对应桌面端:
///   src/server/req.py  -> GetAPPsReq    (GET /pica-apps, isParseRes=False 透传)
///   src/server/req.py  -> LoginAPPReq   (后续跳转登录,本批次不实现)
class PicaAppsRepository {
  final Dio _api = ApiClient.instance;

  /// 获取 Pica Apps 列表
  ///
  /// 桌面端 `GetAPPsReq.isParseRes=False`, 后端响应的 `data` 字段本身就是 list
  /// (而不是包了 `{docs: [...]}`). 移动端同样兼容两种响应形态:
  /// - 直接返回 list:`data: [{...}, {...}]`
  /// - 包裹:`data: { apps: [...] }` / `data: { docs: [...] }`
  Future<List<PicaApp>> getPicaApps() async {
    final response = await _api.get(ApiEndpoints.picaApps);
    final body = response.data;
    final data = body is Map ? (body['data'] ?? body) : body;

    final List<dynamic> raw = data is List
        ? data
        : (data is Map
            ? (data['apps'] ?? data['docs'] ?? data['list'] ?? const [])
            : const []);

    return raw
        .whereType<Map>()
        .map((m) => PicaApp.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }
}

final picaAppsRepositoryProvider = Provider<PicaAppsRepository>((ref) {
  return PicaAppsRepository();
});

/// Pica Apps 列表 Provider
///
/// 第十七批:对齐桌面端 GetAPPsReq.
///
/// 返回应用列表 (可能为空). UI 层在 `error` 时显示网络错误提示,
/// 在 `data` 为空时显示"暂无推荐".
final picaAppsListProvider = FutureProvider<List<PicaApp>>((ref) async {
  return ref.read(picaAppsRepositoryProvider).getPicaApps();
});
