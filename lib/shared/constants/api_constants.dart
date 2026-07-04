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
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String changePassword = '/users/password';
  static const String user = '/user';
  static const String userAvatar = '/users/avatar';
  static const String userTitle = '/users/{id}/title';

  // 漫画
  static const String comics = '/comics';
  static const String comicsRandom = '/comics/random';
  static const String comicsRank = '/comics/leaderboard';
  static const String comicsKnightRank = '/comics/knight-leaderboard';
  static const String comicsSearch = '/comics/search';

  // Pica 号（推荐位）解析
  static const String picaShareSet = 'https://recommend.go2778.com/pic/share/set';
  static const String picaShareGet = 'https://recommend.go2778.com/pic/share/get';
  static const String picaRecommendGet = 'https://recommend.go2778.com/pic/recommend/get';

  // 网络测速
  static const String speedTest = '/speed';
  static const String speedTestPing = '/speed/ping';

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

  // 收藏
  static const String collections = '/collections';

  // 评论
  static const String comments = '/comics/{id}/comments';
  static const String sendComment = '/comics/{id}/comments';

  // 点赞
  static const String like = '/comics/{id}/like';

  // 评论点赞 (桌面端 endpoint)
  static const String commentLike = '/comments/{id}/like';

  // 子评论
  static const String commentChildren = '/comments/{id}/childrens';

  // 评论举报
  static const String commentReport = '/comments/{id}/report';

  // 用户评论
  static const String userComments = '/users/profile/comments';
  static const String myComments = '/users/my-comments';

  // 搜索热词
  static const String keywords = '/keywords';

  // 高级搜索（多条件）— POST /comics/advanced-search
  static const String advancedSearch = '/comics/advanced-search';

  // 漫画推荐 (related comics on detail page)
  static const String comicRecommendation = '/comics/{id}/recommendation';

  // 签到
  static const String punchIn = '/users/punch-in';

  // 用户资料
  static const String userProfile = '/users/profile';

  // 游戏
  static const String games = '/games';
  static const String game = '/games/{id}';

  // 第十七批：第三方应用列表 (Pica Apps) — 对齐桌面端 GetAPPsReq
  //   GET /pica-apps  → 返回 [{title, icon, url, ...}]
  //   Pica Apps 是 Pica 官方在主站里推荐的第三方客户端/工具
  //   点击通常跳转到对应应用市场或下载页
  static const String picaApps = '/pica-apps';

  // 聊天室
  static const String chatRooms = '/chat';
  static const String chatMessages = '/chat/{id}/messages';

  // WebSocket
  static const String wsUrl = 'wss://picaapi.picacomic.com';

  // 漫画列表
  static String comicsList({int page = 1}) => '/comics?page=$page';

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
