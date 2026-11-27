import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/utils/media_url.dart';
import '../../../shared/constants/api_constants.dart';
import '../domain/comic_model.dart';
import '../domain/comment_model.dart';

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
  /// [sort] 排序：`dd` = 新到旧（默认），`da` = 旧到新
  /// 对应桌面端 favorite_view.py `self.sortList = ["dd", "da"]`：
  /// ui_favorite.ui 下拉框 index 0 = "新到旧" = `dd`，index 1 = "旧到新" = `da`。
  /// `dd` 与桌面下拉框第一项一致，作为默认排序。
  Future<List<Comic>> getMyFavourites(
      {int page = 1, String sort = 'dd'}) async {
    final response = await _api.get(
      ApiEndpoints.myFavorites,
      queryParameters: {'s': sort, 'page': page},
    );
    final data = response.data['data'];
    final comics =
        (data['comics'] as List).map((json) => Comic.fromJson(json)).toList();
    return comics;
  }

  /// 获取我的追漫列表
  Future<List<Comic>> getMyFollows({int page = 1}) async {
    final response = await _api.get(
      ApiEndpoints.myFollows,
      queryParameters: {'s': 'dd', 'page': page},
    );
    final data = response.data['data'];
    final comics =
        (data['comics'] as List).map((json) => Comic.fromJson(json)).toList();
    return comics;
  }

  // ================== 搜索 ==================

  /// 基础搜索 (GET /comics/search)
  Future<List<Comic>> search({
    required String q,
    String? categories,
    int page = 1,
  }) async {
    final response = await _api.get(
      ApiEndpoints.comicsSearch,
      queryParameters: {
        'q': q,
        if (categories != null && categories.isNotEmpty) 'c': categories,
        'page': page,
      },
    );
    final data = response.data['data'];
    final docs = (data is Map ? data['comics'] : null) as List? ?? [];
    return docs
        .map((json) => Comic.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// 高级搜索 (POST /comics/advanced-search)
  /// 支持关键词 + 多分类组合筛选
  Future<List<Comic>> advancedSearch({
    required String keyword,
    List<String> categories = const [],
    String sort = '',
    int page = 1,
  }) async {
    final response = await _api.post(
      ApiEndpoints.advancedSearch,
      queryParameters: {'page': page},
      data: {
        'keyword': keyword,
        'categories': categories,
        'sort': sort,
      },
    );
    final data = response.data['data'];
    final docs = (data is Map ? data['comics'] : null) as List? ?? [];
    return docs
        .map((json) => Comic.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ================== 评论系统 ==================

  /// 获取漫画评论
  Future<List<Comment>> getComments(String comicId, {int page = 1}) async {
    final url =
        '${ApiEndpoints.comments.replaceFirst('{id}', comicId)}?page=$page';
    final response = await _api.get(url);
    final data = response.data['data'];
    final docs = data['docs'] as List? ?? [];
    return docs
        .map((c) => Comment.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  /// 发送评论
  Future<void> sendComment(String comicId, String content,
      {String? parentId}) async {
    final url = ApiEndpoints.sendComment.replaceFirst('{id}', comicId);
    await _api.post(
      url,
      data: {
        'content': content,
        if (parentId != null) 'parent': parentId,
      },
    );
  }

  /// 点赞评论 (POST /comments/{id}/like)
  Future<void> likeComment(String commentId) async {
    await _api.post('/comments/$commentId/like');
  }

  /// 获取子评论
  Future<List<Comment>> getCommentChildren(String commentId,
      {int page = 1}) async {
    final url = '/comments/$commentId/childrens?page=$page';
    final response = await _api.get(url);
    final data = response.data['data'];
    final docs = data['docs'] as List? ?? [];
    return docs
        .map((c) => Comment.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  /// 发送子评论
  Future<void> sendCommentChild(String commentId, String content) async {
    await _api.post('/comments/$commentId', data: {'content': content});
  }

  /// 举报评论 (POST /comments/{id}/report)
  Future<void> reportComment(String commentId, {String reason = 'spam'}) async {
    await _api.post(
      '/comments/$commentId/report',
      data: {'reason': reason},
    );
  }

  // ================== 搜索热词 ==================

  /// 获取搜索热词列表 (GET /keywords)
  Future<List<String>> getKeywords() async {
    final response = await _api.get(ApiEndpoints.keywords);
    final data = response.data['data'];
    final list = data['keywords'] as List? ?? [];
    return list.map((e) => e.toString()).toList();
  }

  // ================== 漫画推荐 ==================

  /// 获取相关漫画推荐 (GET /comics/{id}/recommendation)
  Future<List<Comic>> getComicRecommendation(String comicId) async {
    final url = ApiEndpoints.comicRecommendation.replaceFirst('{id}', comicId);
    final response = await _api.get(url);
    final data = response.data['data'];
    final list = data['comics'] as List? ?? [];
    return list
        .map((json) => Comic.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ================== 章节列表（分页） ==================

  /// 获取单页章节列表 (GET /comics/{id}/eps?page=N)
  ///
  /// 返回该页的章节以及分页元信息。
  ///
  /// 第六十二批新增。桌面端 `GetComicsBookEpsReq`（`src/server/req.py:327`）
  /// 的 URL 是 `comics/{cid}/eps?page={page}`，响应体的 `eps` 节点含：
  ///   `docs`  (当前页章节) / `total` (总章节数) / `pages` (总页数)
  ///   / `limit` (每页条数) / `page` (当前页)
  /// 桌面端 `src/tools/book.py:162` 读取 `r.data['eps']["total"]` 作为
  /// `epsCount`（总章节数）。
  Future<EpisodePage> getEpisodePage(String comicId, {int page = 1}) async {
    final response = await _api.get(ApiEndpoints.episodes(comicId, page: page));
    final data = response.data['data'];
    final eps = data['eps'] as Map<String, dynamic>? ?? const {};
    final docs = eps['docs'] as List? ?? [];
    return EpisodePage(
      episodes: docs
          .map((e) => Episode.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: _asInt(eps['total']),
      pages: _asInt(eps['pages']),
      limit: _asInt(eps['limit']),
      page: _asInt(eps['page'], fallback: page),
    );
  }

  /// 获取**全部**章节（自动翻完所有分页），并按桌面端的章节顺序排列。
  ///
  /// 对齐桌面端 `src/view/info/book_eps_view.py:66` `LoadEpsData(page)`：
  /// 桌面端会从第 1 页递归加载到最后一页，把所有章节收进 `epsDict`。
  ///
  /// 第六十二批：移动端此前只请求第 1 页，长篇漫画（真实抓取数据里
  /// `epsCount` 最高 389 章）的其余章节既看不到也下载不到。
  ///
  /// ## 章节顺序（与桌面端逐条对齐）
  ///
  /// 桌面端 `src/tools/book.py:183` 用
  ///   `index = epsCount - epsLimit * (page - 1) - i - 1`
  /// 计算每个章节的下标：`index == 0` 是**最老的一章**，index 越大章节越新。
  /// 桌面端 `src/view/info/book_eps_view.py:105` 用
  ///   `for index in range(0, info.epsCount)` —— **升序**渲染，
  /// 于是章节 1、2、3 …… 依次排列。
  ///
  /// 桌面端 `src/view/info/book_info_view.py:445` 的分页标签
  ///   `start = epsCount - i*epsLimit` 也证实了 **API 第 1 页是最新的章节**
  /// （389 章的漫画第 1 页标签是 "389-190"）。
  ///
  /// 因此**不能**像第一版那样把后续页简单追加到尾部 —— 那会让整张列表
  /// 保持"最新在前"，与桌面端的升序相反。必须用上面的公式算出每个章节的
  /// 下标，再按下标**升序**排列。
  ///
  /// 这一条同时修正了一个**核心阅读入口缺陷**：移动端
  /// `comic_detail_screen.dart` 的"开始阅读"在没有历史记录时取
  /// `initialEpisodeIndex = 0`，即列表第一项。在"最新在前"的顺序下，
  /// 第一项是**最新的一章** —— 新漫画一点"开始阅读"直接跳到最后一章。
  /// 桌面端 `src/view/info/book_info_view.py:594` `StartRead()` 走的是
  /// `OpenReadIndex(0)`，即 `epsId == 0` = **第 1 章**（最老的一章）。
  /// 升序排列后，移动端的 index 0 与桌面端语义完全一致。
  ///
  /// 翻页上限 [maxPages] 是防御性的：正常漫画只有 1~2 页，
  /// 但服务端若返回异常的 `pages` 值，可以避免无限循环。
  Future<List<Episode>> getAllEpisodes(
    String comicId, {
    int maxPages = 50,
  }) async {
    final first = await getEpisodePage(comicId, page: 1);
    if (first.episodes.isEmpty) return first.episodes;

    final all = <Episode>[...first.episodes];
    final totalPages = first.pages;
    if (totalPages > 1) {
      final pageCount = totalPages > maxPages ? maxPages : totalPages;
      for (var page = 2; page <= pageCount; page++) {
        final next = await getEpisodePage(comicId, page: page);
        if (next.episodes.isEmpty) break;
        all.addAll(next.episodes);
      }
    }

    return sortEpisodesByDesktopOrder(
      all,
      epsCount: first.total,
      epsLimit: first.limit,
    );
  }

  /// 按桌面端 `src/tools/book.py:183` 的下标公式把章节排成**升序**。
  ///
  /// 桌面端公式：
  /// ```text
  /// index = epsCount - epsLimit * (page - 1) - i - 1
  /// ```
  /// 其中 `page` 是该章节所在页（1 起），`i` 是它在页内的位置（0 起）。
  /// `index == 0` 是最老的一章。
  ///
  /// 桌面端**没有**用 API 自带的 `order` 字段排序
  /// （`src/tools/book.py:199-200` 的 `info.eps.sort(key=lambda a: a.order)`
  /// 是被注释掉的），代码里还留有注释"居然有重复的order"——
  /// 说明 `order` 字段并不总是唯一/可靠，位置公式才是桌面端的权威顺序。
  /// 移动端此前直接沿用 API 返回顺序，等价于"最新在前"，与桌面端相反。
  ///
  /// 防御性回退：当服务端没给出 `total` / `limit` 时，无法计算下标，
  /// 此时保持 API 原始顺序（不排序），而不是猜一个顺序。
  @visibleForTesting
  static List<Episode> sortEpisodesByDesktopOrder(
    List<Episode> episodes, {
    required int epsCount,
    required int epsLimit,
  }) {
    if (epsCount <= 0 || epsLimit <= 0) return episodes;

    final indexed = <({Episode episode, int index})>[];
    var page = 1;
    var consumed = 0;
    for (final episode in episodes) {
      final i = consumed;
      consumed++;
      indexed.add((
        episode: episode,
        index: epsCount - epsLimit * (page - 1) - i - 1,
      ));
      if (consumed == epsLimit) {
        consumed = 0;
        page++;
      }
    }

    indexed.sort((a, b) => a.index.compareTo(b.index));
    return indexed.map((e) => e.episode).toList();
  }

  static int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  // ================== 章节图片列表（分页） ==================

  /// 获取单页章节图片 (GET /comics/{cid}/order/{eid}/pages?page=N)
  ///
  /// 第六十二批新增。桌面端 `GetComicsBookOrderReq`（`src/server/req.py:337`）
  /// 的 URL 是 `comics/{cid}/order/{eid}/pages?page={page}`，响应体的
  /// `pages` 节点含：
  ///   `docs`  (当前页图片 doc) / `total` (该章节图片总数)
  ///   / `pages` (分页组数) / `limit` (每组图片数) / `page` (当前页)
  ///
  /// 桌面端 `src/tools/book.py:221-241` 读取同一组字段
  /// （`total` -> `maxPics`，`pages` -> `maxPicPages`，`limit` -> `picLimit`）。
  ///
  /// 图片 doc 是**包装对象**，媒体字段在 `media` 子对象下，
  /// 见 `pageDocImageUrl`。
  Future<ImagePage> getImagePage(
    String comicId,
    String episodeId, {
    int page = 1,
    CancelToken? cancelToken,
  }) async {
    final response = await _api.get(
      ApiEndpoints.episodePages(comicId, episodeId, page: page),
      cancelToken: cancelToken,
    );
    final data = response.data['data'];
    final pages = data['pages'] as Map<String, dynamic>? ?? const {};
    final docs = pages['docs'] as List? ?? [];
    return ImagePage(
      urls: pageDocImageUrls(docs),
      total: _asInt(pages['total']),
      pages: _asInt(pages['pages'], fallback: 1),
      limit: _asInt(pages['limit']),
      page: _asInt(pages['page'], fallback: page),
    );
  }

  /// 获取**全部**章节图片（自动翻完所有分页组）。
  ///
  /// 对齐桌面端 `src/tools/book.py:260-285`：桌面端把图片按
  /// `index = (page - 1) * limit + i` 放进 `epsInfo.pics`，
  /// 并在下载时按 `loadPage = task.index // picLimit + 1`（`task_download.py:283`）
  /// 定位到具体分页组 —— 即桌面端**确实按需翻页**取图片。
  ///
  /// 第六十二批：移动端此前固定只请求第 1 页。真实 API 抓取数据
  /// （150,574 条漫画）显示，6,354 部**单章**漫画的一个章节内图片数
  /// 超过 200（服务端每页上限），最多的一章有 4,896 张 = 25 个分页组。
  /// 这些章节在移动端**只能看到前 200 张**，下载也只能拿到前 200 张。
  ///
  /// [maxPages] 是防御性上限：正常章节 1 组，异常章节最多 25 组。
  ///
  /// [cancelToken] 让调用方（下载器）能中断翻页过程中的 HTTP 请求。
  /// 第六十二批修复：此前下载器改用本方法后，**丢掉了原来传给
  /// `_api.get(...)` 的 cancelToken**，导致"暂停/取消下载"只能在
  /// 拿到完整列表之后才生效 —— 一章 4896 张图时用户点了取消仍会等
  /// 25 个分页组全部下载完。
  Future<List<String>> getAllEpisodeImages(
    String comicId,
    String episodeId, {
    int maxPages = 50,
    CancelToken? cancelToken,
  }) async {
    final first = await getImagePage(comicId, episodeId,
        page: 1, cancelToken: cancelToken);
    if (first.urls.isEmpty) return first.urls;

    final all = <String>[...first.urls];
    final totalPages = first.pages;
    if (totalPages <= 1) return all;

    final pageCount = totalPages > maxPages ? maxPages : totalPages;
    for (var page = 2; page <= pageCount; page++) {
      final next = await getImagePage(comicId, episodeId,
          page: page, cancelToken: cancelToken);
      if (next.urls.isEmpty) break;
      all.addAll(next.urls);
    }
    return all;
  }
}

/// Provider
final comicRepositoryProvider = Provider<ComicRepository>((ref) {
  return ComicRepository();
});
