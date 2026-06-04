import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../shared/constants/api_constants.dart';
import '../domain/game_model.dart';

/// 游戏区 Repository
///
/// 对应桌面端: src/view/game/game_view.py + src/view/info/game_info_view.py
/// API:
///   GET /games?page=N
///   GET /games/{id}
class GameRepository {
  final Dio _api = ApiClient.instance;

  /// 获取游戏列表（分页）
  /// 对应桌面端: `GetGameReq(page)` -> GET /games?page=N
  Future<GameListPage> getGames({int page = 1}) async {
    final response = await _api.get(
      ApiEndpoints.games,
      queryParameters: {'page': page},
    );
    final data = response.data is Map
        ? (response.data['data'] is Map
            ? response.data['data'] as Map<String, dynamic>
            : response.data as Map<String, dynamic>)
        : <String, dynamic>{};
    return GameListPage.fromJson(data);
  }

  /// 获取游戏详情
  /// 对应桌面端: `GetGameInfoReq(gameId)` -> GET /games/{id}
  Future<Game> getGameInfo(String gameId) async {
    final url = ApiEndpoints.game.replaceFirst('{id}', gameId);
    final response = await _api.get(url);
    final body = response.data is Map
        ? response.data as Map<String, dynamic>
        : <String, dynamic>{};
    final data = (body['data'] is Map)
        ? body['data'] as Map<String, dynamic>
        : body;
    final game = data['game'] is Map
        ? data['game'] as Map<String, dynamic>
        : data;
    return Game.fromDetailJson(game);
  }
}

final gameRepositoryProvider = Provider<GameRepository>((ref) {
  return GameRepository();
});

/// 游戏列表 Provider（按页号缓存）
final gamesListProvider =
    FutureProvider.family<GameListPage, int>((ref, page) async {
  return ref.read(gameRepositoryProvider).getGames(page: page);
});

/// 游戏详情 Provider（按 ID 缓存）
final gameDetailProvider =
    FutureProvider.family<Game, String>((ref, gameId) async {
  return ref.read(gameRepositoryProvider).getGameInfo(gameId);
});
