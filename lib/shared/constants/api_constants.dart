/// API 端点常量
/// Base URL 由用户在设置中配置，默认指向 picacg API
class ApiEndpoints {
  ApiEndpoints._();

  // 默认 API 地址（可配置）
  static const String defaultBaseUrl = 'https://picaapi.picacomic.com';

  // 认证
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String user = '/user';
  static const String userAvatar = '/user/avatar';
  static const String changePassword = '/auth/password';

  // 漫画
  static const String comics = '/comics';
  static const String comicsRandom = '/comics/random';
  static const String comicsRank = '/comics/leaderboard';
  static const String comicsSearch = '/comics/search';

  // 分类
  static const String categories = '/categories';
  static const String categoryComics = '/category'; // ?ccat=<id>

  // 标签
  static const String tags = '/tags';

  // 收藏
  static const String myFavorites = '/my/favourites';
  static const String favorite = '/comics/{id}/favourite';

  // 追漫
  static const String myFollows = '/my/follows';
  static const String follow = '/comics/{id}/follow';

  // 评论
  static const String comments = '/comics/{id}/comments';
  static const String sendComment = '/comics/{id}/comments';

  // 点赞
  static const String like = '/comics/{id}/like';

  // 游戏
  static const String games = '/games';
  static const String game = '/games/{id}';

  // 聊天室
  static const String chatRooms = '/chat';
  static const String chatMessages = '/chat/{id}/messages';

  // WebSocket
  static const String wsUrl = 'wss://picaapi.picacomic.com';

  // 搜索
  static String search({required String q, String? categories, int? page}) {
    String url = '$comicsSearch?q=$q&page=${page ?? 1}';
    if (categories != null) url += '&c=$categories';
    return url;
  }

  // 漫画详情
  static String comicDetail(String id) => '/comics/$id';

  // 章节图片
  static String episodePages(String comicId, String episodeId) =>
      '/comics/$comicId/eps/$episodeId/pages';

  // 章节列表
  static String episodes(String comicId) => '/comics/$comicId/eps';

  // 用户收藏夹
  static String userFavorites(String uid, {int page = 1}) =>
      '/users/$uid/favourites?page=$page';
}
