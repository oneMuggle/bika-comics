import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../shared/constants/api_constants.dart';
import '../domain/knight_model.dart';

/// 骑士榜 Repository
class KnightRepository {
  final Dio _api = ApiClient.instance;

  /// 获取骑士榜（用户排名）
  ///
  /// 对应桌面端: `req.KnightRankReq` -> GET /comics/knight-leaderboard
  Future<List<KnightUser>> getKnightRank() async {
    final response = await _api.get(ApiEndpoints.comicsKnightRank);
    final rank = KnightRank.fromJson(
      response.data as Map<String, dynamic>,
    );
    return rank.users;
  }
}

final knightRepositoryProvider = Provider<KnightRepository>((ref) {
  return KnightRepository();
});

/// 骑士榜 FutureProvider
final knightRankProvider = FutureProvider<List<KnightUser>>((ref) async {
  return ref.read(knightRepositoryProvider).getKnightRank();
});
