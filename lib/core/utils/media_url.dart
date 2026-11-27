/// 哔咔 API 图片 URL 解析
///
/// 对应桌面端 `src/tools/tool.py` 的 `ToolUtil.GetRealUrl(url, path)`：
///
/// ```python
/// @staticmethod
/// def GetRealUrl(url, path):
///     if path:
///         if url[-7:] != "static/":
///             return url + "/static/" + path
///         else:
///             return url + path
///     else:
///         return url
/// ```
///
/// ## 为什么必须有这个工具
///
/// 哔咔 API 返回的媒体对象形如：
/// ```json
/// { "fileServer": "https://storage1.picacomic.com",
///   "path": "tobeimg/xxx/rs:fill:300:400:0/g:sm/aHR0cHM6....jpg" }
/// ```
///
/// `path` 是**相对路径**（无 scheme、无 host），`fileServer` 才是主机。
/// 桌面端把两者**分开存进 SQLite 的两列**（`path` / `fileServer`），
/// 每次用图时再拼成 `fileServer + "/static/" + path`。
///
/// 真实数据佐证（本机 `extract_db/book.db`，由桌面端从真实 API 抓取）：
/// ```
/// path       = 'tobeimg/gJ6Mi_.../aHR0cHM6Ly9zdG9yYWdlMS5waWNhY29taWMuY29tL3N0YXRpYy81YzdjNWNlMC0....jpg'
/// fileServer = 'https://storage1.picacomic.com'
/// ```
/// `path` 以 `http` 开头？否 → 确实是相对路径。
///
/// 移动端此前直接用 `path`（或错误地拼 `'$fileServer$path'`），
/// 结果是：
/// - `path` 单独用 → 相对路径，`CachedNetworkImage` 无法解析，图片全挂；
/// - `'$fileServer$path'` → `https://storage1.picacomic.comtobeimg/...`，
///   host 与 path 之间少一个分隔符，URL 非法。
///
/// ## 覆盖范围
///
/// 凡是 pica API 返回 `{fileServer, path}` 形态的媒体对象都要走这里：
/// `comic.thumb` / `comic.cover` / `page.media` / `user.avatar` /
/// `game.icon` / `comment.avatar` / `app.icon` / `knight.avatar`。
library;

/// 哔咔媒体对象（API 返回的 `{fileServer, path, originalName}` 结构）
class PicaMedia {
  /// 文件服务器地址，如 `https://storage1.picacomic.com`
  final String fileServer;

  /// 相对路径，如 `tobeimg/xxx/....jpg`
  final String path;

  /// 原始文件名
  final String originalName;

  const PicaMedia({
    required this.fileServer,
    required this.path,
    this.originalName = '',
  });

  const PicaMedia.empty()
      : fileServer = '',
        path = '',
        originalName = '';

  /// 从 API 返回的动态对象解析。
  ///
  /// 兼容三种形态：
  /// 1. `{fileServer, path}` —— 标准形态（真实 pica API 形态）
  /// 2. `{url}` 或 `{path}` 已是完整 URL —— 原样返回
  /// 3. 字符串 —— 原样返回
  static PicaMedia fromJson(dynamic raw) {
    if (raw == null) return const PicaMedia.empty();
    if (raw is String) {
      return PicaMedia(fileServer: '', path: raw, originalName: '');
    }
    if (raw is! Map) return const PicaMedia.empty();

    final fileServer = raw['fileServer']?.toString() ?? '';
    var path = raw['path']?.toString() ?? '';
    final originalName = raw['originalName']?.toString() ?? '';

    // 已经是完整 URL（某些接口直接返回 url 而非 fileServer+path）
    final url = raw['url']?.toString();
    if (path.isEmpty && url != null && url.isNotEmpty) {
      path = url;
    }
    return PicaMedia(
      fileServer: fileServer,
      path: path,
      originalName: originalName,
    );
  }

  /// 是否为空媒体对象
  bool get isEmpty => fileServer.isEmpty && path.isEmpty;

  /// 最终可访问的 URL —— 桌面端 `GetRealUrl` 的等价实现。
  String get url => resolveMediaUrl(fileServer, path);

  @override
  String toString() => 'PicaMedia(fileServer: $fileServer, path: $path)';
}

/// 把桌面端 `ToolUtil.GetRealUrl(url, path)` 移植到 Dart。
///
/// 规则（与桌面端逐字节一致）：
/// - `path` 为空 → 返回 `fileServer`
/// - `fileServer` 已以 `static/` 结尾 → 返回 `fileServer + path`
/// - 否则 → 返回 `fileServer + "/static/" + path`
///
/// 额外做了两处**防御性**处理（桌面端没有，但移动端需要）：
/// 1. `path` 已是绝对 URL（带 `http://` / `https://`）→ 原样返回。
///    这是防御性的：某些接口（如桌面端 `category.py:80` 归一化的
///    `https://wikawika.xyz/static/`）确实会给出完整地址。
/// 2. `fileServer` 与 `path` 之间保证恰好一个 `/`。
///    桌面端隐含假设 `fileServer` 不带尾斜杠、`path` 不带首斜杠；
///    移动端从 JSON 直取，不做这个假设，所以要自己保证。
String resolveMediaUrl(String fileServer, String path) {
  final fs = fileServer.trim();
  final p = path.trim();

  if (p.isEmpty) return fs;
  // path 已是绝对 URL —— 直接用
  if (p.startsWith('http://') || p.startsWith('https://')) return p;
  if (fs.isEmpty) return p;

  // 桌面端原规则：fileServer 已含 'static/' 时不再重复拼接
  if (fs.endsWith('static/')) {
    return '$fs${p.startsWith('/') ? p.substring(1) : p}';
  }
  // 桌面端原规则：fileServer + '/static/' + path
  final normalizedFs = fs.endsWith('/') ? fs.substring(0, fs.length - 1) : fs;
  final normalizedPath = p.startsWith('/') ? p.substring(1) : p;
  return '$normalizedFs/static/$normalizedPath';
}

/// 从 API 返回的媒体对象直接解析出最终 URL。
///
/// 等价于 `PicaMedia.fromJson(raw).url`，但对 `null` / 非 Map 输入更宽容。
String mediaUrlFrom(dynamic raw) {
  if (raw == null) return '';
  if (raw is String) return raw;
  if (raw is! Map) return '';
  final fileServer = raw['fileServer']?.toString() ?? '';
  final path = raw['path']?.toString() ?? '';
  final url = raw['url']?.toString();
  if (fileServer.isEmpty && path.isEmpty && url != null) return url;
  return resolveMediaUrl(fileServer, path);
}

/// 从**章节页面文档**（page doc）解析出图片 URL。
///
/// ## 为什么需要这个函数
///
/// pica 的 `/comics/{id}/order/{eid}/pages` 返回的每一项是**包装对象**：
/// ```json
/// { "_id": "...",
///   "media": { "fileServer": "...", "path": "...", "originalName": "..." } }
/// ```
/// 桌面端 `src/tools/book.py:251` 正是 `ToolUtil.ParseFromData(picInfo, data['media'])`,
/// 即**从 `media` 子对象**取 fileServer/path。
///
/// 移动端此前把**整个 page doc** 传给 `mediaUrlFrom`，而 `mediaUrlFrom` 只读
/// 顶层 `fileServer` / `path` / `url` —— 对包装对象一律返回空串。
/// 阅读器 (`reader_screen.dart`) 用的是 `p['media']`，所以**阅读正常、下载全空**：
/// 同一个 API 两个消费点写法不一致，每章下载 0 张图。
///
/// ## 兼容性
///
/// 少数情况下 page doc 可能**直接**带 `fileServer` / `path`（没有 `media` 包装）。
/// 因此这里**先看 `media` 子对象，没有再看顶层**，两种形态都能取到 URL。
/// 这条回退是防御性的：真实 API 的 page doc 恒为包装形态。
String pageDocImageUrl(dynamic pageDoc) {
  if (pageDoc is! Map) return '';

  final media = pageDoc['media'];
  if (media is Map) {
    final url = mediaUrlFrom(media);
    if (url.isNotEmpty) return url;
  }
  // 回退：直接读顶层的 fileServer / path / url
  return mediaUrlFrom(pageDoc);
}

/// 从一组章节页面文档中解析出全部图片 URL（自动跳过解析不出的页）。
///
/// 下载器与阅读器共用此函数，保证两个消费点**永远**取到同一批 URL。
List<String> pageDocImageUrls(Iterable<dynamic> pageDocs) {
  final result = <String>[];
  for (final doc in pageDocs) {
    final url = pageDocImageUrl(doc);
    if (url.isNotEmpty) result.add(url);
  }
  return result;
}
