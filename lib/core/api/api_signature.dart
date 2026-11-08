import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Pica API 请求签名器 — 第五十九批新增（P0 修复）
///
/// 对应桌面端 `src/tools/tool.py` 中的 `ToolUtil.GetHeader` /
/// `ToolUtil.__ConFromNative` / `ToolUtil.__SigFromNative` / `ToolUtil.HashKey`。
///
/// 桌面端对每个 API 请求都会计算 `signature` 头：
///
/// ```text
/// src      = <path> + <time> + <nonce> + <METHOD> + <apiKey>     （全部小写后签名）
/// signature = HMAC-SHA256(appSecret, src).hexdigest()
/// ```
///
/// 其中 `appSecret` 是桌面端从 Android 原生库逆向得到的常量
/// （`ToolUtil.__SigFromNative`，63 字符）。
///
/// **第五十九批修复的背景**：移动端此前**完全没有**实现这一层，
/// `_AuthInterceptor` 只发送 `api-key` / `app-version` / `app-build` /
/// `User-Agent` / `Content-Type`，缺少 `accept`、`app-channel`、`time`、
/// `app-uuid`、`nonce`、`signature`、`image-quality`、`app-platform`、
/// `app-build-version`、`version`。同时移动端使用的 `api-key` 是一串
/// **人为填充的假值**（`C69BAF41DA5ABD1FF2C0A1D2...`），与桌面端真实的
/// `C69BAF41DA5ABD1FFEDC6D2FEA56B` 不符——签名与 api-key 必须成对使用，
/// 错误的 api-key 会让签名直接失效。
///
/// 本类的实现通过**桌面端代码本身**导出的已知答案向量（KAT）验证，
/// 见 `test/api_signature_test.dart`。
class ApiSignature {
  ApiSignature._();

  /// 桌面端 `config.ApiKey`
  static const String apiKey = 'C69BAF41DA5ABD1FFEDC6D2FEA56B';

  /// 桌面端 `config.Version`
  static const String appVersion = '2.2.1.3.3.4';

  /// 桌面端 `config.BuildVersion`
  static const String appBuildVersion = '45';

  /// 桌面端 `config.Accept`
  static const String accept = 'application/vnd.picacomic.com.v1+json';

  /// 桌面端 `config.AppChannel`
  static const String appChannel = '3';

  /// 桌面端 `config.Uuid`
  static const String appUuid = 'defaultUuid';

  /// 桌面端 `config.Platform`
  static const String appPlatform = 'android';

  /// 桌面端 `config.ImageQuality`
  static const String imageQuality = 'original';

  /// 桌面端 `config.Agent`
  static const String userAgent = 'okhttp/3.8.1';

  /// 桌面端 `config.UpdateVersion`
  static const String clientVersion = 'v1.5.4';

  /// 桌面端 `ToolUtil.__SigFromNative()` 返回的应用密钥（63 字符）。
  ///
  /// 该常量由桌面端从 Android 原生 so 逆向得到（`tool.py` 中的 IDA PRO
  /// 反编译注释），此处逐字符保持一致。
  static const String appSecret =
      r'~d}$Q7$eIni=V)9\RK/P.RM4;9[7|@/CA}b~OW!3?EV`:<>M7pddUBL5n|0/*Cn';

  /// 计算被签名的字符串。
  ///
  /// 桌面端 `ToolUtil.__ConFromNative` 只取 `datas[1..5]`：
  /// `path`、`time`、`nonce`、`method`、`apiKey`。
  ///
  /// 注意桌面端拼的是 **原始 path**（不含 query string 的 host 部分，
  /// 因为 `config.Url` 已被 `replace` 掉），并且最后对整个字符串
  /// 做 `.lower()` 后再参与 HMAC。
  static String buildSignedSource({
    required String path,
    required String time,
    required String nonce,
    required String method,
    String apiKeyOverride = apiKey,
  }) {
    final buffer = StringBuffer()
      ..write(path)
      ..write(time)
      ..write(nonce)
      ..write(method)
      ..write(apiKeyOverride);
    return buffer.toString();
  }

  /// 把 Dio 的请求路径规范化为桌面端参与签名的**相对路径**。
  ///
  /// 桌面端 `config.Url = "https://picaapi.picacomic.com/"`（**带尾部斜杠**），
  /// 构造 URL 时写作 `config.Url + "comics?page=1&c=VC&s="`，签名时取
  /// `_url.replace(config.Url, "")`，结果是：
  ///
  /// ```text
  /// comics?page=1&c=VC&s=        ← 无前导斜杠、带 query string
  /// ```
  ///
  /// 第五十九批修复：此前移动端直接把 Dio 的 `options.path` 当作待签名字符串。
  /// 但 Dio 的 `options.path` **不含 `queryParameters`**，而移动端 repository
  /// 普遍使用 `queryParameters` 传参（见 `comic_repository.dart`），
  /// 导致实际签名的字符串缺少 query string，与桌面端不一致 → 签名校验失败。
  /// 同时移动端端点常量带前导斜杠（`/comics`），桌面端没有。
  ///
  /// 本方法把 Dio 的 `options.uri`（含 query string）统一还原为桌面端形式。
  ///
  /// ## 与桌面端 `replace` 的等价映射
  ///
  /// 桌面端签名对象 = `_url.replace(config.Url, "")`，因此分两种情况：
  ///
  /// 1. **同源**（URL 以 `config.Url` 开头）→ 得到相对路径
  ///    `comics?page=1&c=VC&s=`。
  /// 2. **异源**（第三方域名，如 `recommend.go2778.com`）→ `replace` 不生效，
  ///    签名对象是**完整 URL**。
  ///
  /// ## 代理场景（重要）
  ///
  /// 移动端的 base URL 可由用户在设置页自定义，形如
  /// `https://bika-api.jpacg.cc/picaapi.picacomic.com`（**带 path 前缀**）。
  /// 此时若只剥离 origin，签名对象会变成
  /// `picaapi.picacomic.com/comics?page=1`——与服务端不一致，签名必然失败。
  ///
  /// 桌面端不存在这个问题：它**先**按 `config.Url` 签名，**再**在
  /// `src/server/server.py` 里改写 URL 走代理：
  /// ```python
  /// if request.proxyUrl:
  ///     host = ToolUtil.GetUrlHost(request.url)
  ///     request.url = request.url.replace(host, request.proxyUrl + "/" + host)
  /// ```
  /// 所以移动端必须剥离 baseUrl 的**整个 path 前缀**（不只是 origin），
  /// 才能得到与桌面端一致的相对路径。
  ///
  /// [uri] 必须是以 base URL 为 origin 的完整 URI（Dio 的 `options.uri`）。
  /// [baseUrl] 为当前生效的 API base URL。
  static String normalizeSignedPath(Uri uri, String baseUrl) {
    final base = Uri.tryParse(baseUrl.trim());
    final sameOrigin = base != null &&
        (base.scheme == 'http' || base.scheme == 'https') &&
        base.origin == uri.origin;

    if (!sameOrigin) {
      // 异源（第三方域名）：桌面端 replace 不生效 → 签名对象是完整 URL。
      // fragment 不会上传到服务器，因此绝不能参与签名。
      //
      // 第五十九批修复：`Uri.replace(fragment: '')` 会留下一个空的 fragment，
      // `toString()` 因此输出 "...#"。而桌面端的 `url.replace(config.Url, "")`
      // 不会产生任何 "#"。带上 "#" 会导致签名与服务端计算结果不一致。
      // 这里改用 `uri.removeFragment()`（Dart 3.0+），语义等价于桌面端。
      return uri.removeFragment().toString();
    }

    var path = uri.path;

    // 剥离 baseUrl 的 path 前缀（代理场景）。
    final basePath = _trimTrailingSlash(base.path);
    if (basePath.isNotEmpty && path.startsWith(basePath)) {
      final rest = path.substring(basePath.length);
      // 边界检查：剩余部分必须为空或以 '/' 开头，
      // 避免 "https://a.com" 误匹配 "https://a.com.evil.com"。
      if (rest.isEmpty || rest.startsWith('/')) {
        path = rest;
      }
    }

    // 去掉前导斜杠（桌面端 config.Url 已包含尾部斜杠，replace 后不会有前导斜杠）
    while (path.startsWith('/')) {
      path = path.substring(1);
    }

    // 拼回 query string（Dio 的 options.path 不含 queryParameters）
    var result = path;
    if (uri.hasQuery && uri.query.isNotEmpty) {
      result = '$result?${uri.query}';
    }
    return result;
  }

  /// 去掉字符串末尾的斜杠。
  static String _trimTrailingSlash(String value) {
    var v = value;
    while (v.endsWith('/')) {
      v = v.substring(0, v.length - 1);
    }
    return v;
  }

  /// HMAC-SHA256 十六进制签名 — 对应桌面端 `ToolUtil.HashKey`。
  static String hashKey(String source, String secret) {
    final key = secret.codeUnits;
    final hmac = Hmac(sha256, key);
    return hmac.convert(utf8.encode(source.toLowerCase())).toString();
  }

  /// 生成 32 位十六进制 nonce。
  ///
  /// 桌面端用 `str(uuid.uuid1()).replace("-", "")`，即 UUID1 去掉连字符。
  /// 这里用 `Random.secure()` 生成同形态的 32 位十六进制串。
  static String generateNonce([Random? random]) {
    final rng = random ?? Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// 当前秒级时间戳（桌面端 `str(int(time.time()))`）。
  static String currentTimestamp() =>
      (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();

  /// 构造一组完整的 API 请求头。
  ///
  /// [path] 必须是**相对于 API base URL 的路径**（如 `comics?page=1`），
  /// 与桌面端 `ToolUtil.GetHeader(url, method)` 中 `url.replace(config.Url, "")`
  /// 的结果一致。可用 [normalizeSignedPath] 从 Dio 的 `options.uri` 得到。
  ///
  /// 第五十九批修复：桌面端 `GetHeader` 只在 method 为 post/put 时才附加
  /// `Content-Type`，且请求头集合是固定的 13 个（原实现多发了一个
  /// `app-build`，且对所有请求都强设 Content-Type）。
  static Map<String, String> buildHeaders({
    required String path,
    required String method,
    String? time,
    String? nonce,
    String apiKeyOverride = apiKey,
  }) {
    final t = time ?? currentTimestamp();
    final n = nonce ?? generateNonce();
    final src = buildSignedSource(
      path: path,
      time: t,
      nonce: n,
      method: method,
      apiKeyOverride: apiKeyOverride,
    );
    final signature = hashKey(src, appSecret);

    final headers = <String, String>{
      'api-key': apiKeyOverride,
      'accept': accept,
      'app-channel': appChannel,
      'time': t,
      'app-uuid': appUuid,
      'nonce': n,
      'signature': signature,
      'app-version': appVersion,
      'image-quality': imageQuality,
      'app-platform': appPlatform,
      'app-build-version': appBuildVersion,
      'user-agent': userAgent,
      'version': clientVersion,
    };
    // 桌面端：if method.lower() in ["post", "put"]
    final lowerMethod = method.toLowerCase();
    if (lowerMethod == 'post' || lowerMethod == 'put') {
      headers['Content-Type'] = 'application/json; charset=UTF-8';
    }
    return headers;
  }
}
