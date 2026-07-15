/// API 端点常量
/// Base URL 由用户在设置中配置，默认指向 picacg API
class ApiEndpoints {
  ApiEndpoints._();

  // 默认 API 地址（可配置）
  static const String defaultBaseUrl = 'https://picaapi.picacomic.com';

  // 认证
  // 第二十四批追加修复：登录端点对齐桌面端 LoginReq (auth/sign-in)
  static const String login = '/auth/sign-in';
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
  static const String picaShareSet =
      'https://recommend.go2778.com/pic/share/set';
  static const String picaShareGet =
      'https://recommend.go2778.com/pic/share/get';
  static const String picaRecommendGet =
      'https://recommend.go2778.com/pic/recommend/get';

  // 网络测速
  static const String speedTest = '/speed';
  static const String speedTestPing = '/speed/ping';

  // 分类
  static const String categories = '/categories';
  // 第二十四批追加修复：原 `/category?ccat=<id>` 占位常量已移除；
  // 真实端点由同名静态方法 `categoryComics(category, page, sort)` 构造
  // （对齐桌面端 CategoriesSearchReq `comics?page=&c=&s=`，c 为分类标题，
  // 需要 URL 编码）。

  // 标签
  static const String tags = '/tags';

  // 收藏
  // 第二十四批追加修复：收藏列表端点对齐桌面端 FavoritesReq
  //   `users/favourite?s={sort}&page={page}`
  // 旧 `/my/favourites` 在新版服务端不再返回正确字段。
  static const String myFavorites = '/users/favourite';
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
  // 第二十四批追加修复：阅读器端点对齐桌面端 GetComicsBookOrderReq
  //   `comics/{cid}/order/{eid}/pages?page=1`
  // 旧 `/comics/{cid}/eps/{eid}/pages` 在新版服务端返回字段不一致。
  /// 构造章节图片 URL（包含默认 page=1 查询参数）。
  static String episodePages(String comicId, String episodeId,
          {int page = 1}) =>
      '/comics/$comicId/order/$episodeId/pages?page=$page';

  // 章节列表
  static String episodes(String comicId) => '/comics/$comicId/eps';

  // 用户收藏夹
  static String userFavorites(String uid, {int page = 1}) =>
      '/users/$uid/favourites?page=$page';

  // 第二十四批追加修复：分类漫画搜索。
  // 对齐桌面端 CategoriesSearchReq
  //   `comics?page={page}&c={quote(categories)}&s={sort}`
  // [category] 为分类标题（不是 id），将被 `Uri.encodeQueryComponent`
  // 编码。空字符串/空 sort 也会保留 `c=`/`s=` 形参与桌面端一致。
  static String categoryComics({
    required String category,
    int page = 1,
    String sort = '',
  }) {
    final c = Uri.encodeQueryComponent(category);
    return '$comics?page=$page&c=$c&s=$sort';
  }
}
