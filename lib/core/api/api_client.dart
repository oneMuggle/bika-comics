import 'package:dio/dio.dart';

import '../../shared/constants/api_constants.dart';
import '../storage/secure_storage.dart';
import '../storage/settings_storage.dart';
import '../utils/proxy_selector.dart';
import 'api_signature.dart';

/// API 客户端单例
/// 使用 Dio 实现，支持代理配置和 Token 自动注入
class ApiClient {
  ApiClient._();

  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      responseType: ResponseType.json,
    ),
  );

  /// 解析当前生效的 API Base URL：
  /// 1. 优先返回用户在设置页配置的自定义地址（来自 SettingsStorage 同步缓存）
  /// 2. 否则返回 [ApiEndpoints.defaultBaseUrl]
  ///
  /// 第二十五批：之前 baseUrl 始终硬编码为 [ApiEndpoints.defaultBaseUrl]，
  /// 导致设置页保存的自定义 API 地址无法生效。该方法通过 `SettingsStorageHolder`
  /// 同步访问预加载的缓存（由 `main()` 在 runApp 之前调用 populateCache 填充）。
  static String resolveBaseUrl() {
    try {
      final settings = SettingsStorageHolder.instance;
      final custom = settings.getApiBaseUrlSync();
      if (custom != null &&
          custom.isNotEmpty &&
          ApiEndpoints.isValidBaseUrl(custom)) {
        return custom;
      }
    } on StateError {
      // SettingsStorageHolder 未初始化（仅在测试场景下可能发生），回退默认值。
    }
    return ApiEndpoints.defaultBaseUrl;
  }

  /// 获取配置后的 Dio 实例
  /// 每次调用都会根据当前设置重新配置代理和 Base URL
  static Dio get instance {
    _dio.options.baseUrl = resolveBaseUrl();

    // 第五十九批：真正应用代理配置。此前这里只有一句「简化处理」的注释，
    // 没有任何代码把设置页保存的代理接到 Dio 上 —— 代理开关对请求完全无效。
    ProxySelector.applyToDio(_dio, resolveProxyConfig());

    // 移除旧拦截器，重新添加
    _dio.interceptors.clear();
    _dio.interceptors.add(_AuthInterceptor());
    _dio.interceptors.add(_LoggingInterceptor());

    return _dio;
  }

  /// 读取当前生效的代理配置（同步读缓存，未配置时返回 null）。
  static ProxyConfig? resolveProxyConfig() {
    try {
      final settings = SettingsStorageHolder.instance;
      final config = settings.getProxyConfigSync();
      if (config == null) return null;
      if (!config.isUsable) return null;
      return config;
    } on StateError {
      // SettingsStorageHolder 未初始化（仅在测试场景下可能发生）。
      return null;
    }
  }

  /// 创建一个应用了当前代理配置与超时设置的 Dio 实例。
  ///
  /// 第五十九批：此前 `lib/` 下有 4 处各自 `Dio()` / `Dio(BaseOptions(...))`
  /// 的独立实例（测速下载、分享服务、聊天、动态），它们**完全绕过了代理**，
  /// 导致用户开启代理后这些请求仍然直连。
  ///
  /// 统一从这里创建即可保证所有请求都走同一套代理 + 超时配置。
  /// 注意：这些实例多为**一次性**用途（发一次请求就结束），因此每次都
  /// 新建 adapter 是可接受的；只有 [instance] 这种长生命周期单例才需要
  /// 幂等处理（见 [ProxySelector.applyToDio]）。
  static Dio createClient({
    BaseOptions? options,
    String? baseUrl,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Map<String, dynamic>? headers,
  }) {
    final dio = Dio(
      options ??
          BaseOptions(
            // `BaseOptions.baseUrl` 是非空 `String`，不能直接传 null。
            // 留空字符串即可（dio 会在请求时拼接完整 URL）。
            baseUrl: baseUrl ?? '',
            connectTimeout:
                connectTimeout ?? const Duration(seconds: 15),
            receiveTimeout:
                receiveTimeout ?? const Duration(seconds: 30),
            sendTimeout: const Duration(seconds: 30),
            responseType: ResponseType.json,
            headers: headers,
          ),
    );
    ProxySelector.applyToDio(dio, resolveProxyConfig());
    return dio;
  }

  /// 用 [client] 发起一次请求，并保证其 [Dio] / `HttpClient` 被关闭。
  ///
  /// 第六十批：`createClient` 每次调用都会新建一个 `Dio`，而
  /// `IOHttpClientAdapter` 会持有一个 `HttpClient`
  /// （dio-5.10.0 `lib/src/adapters/io_adapter.dart:241` `_cachedHttpClient`）。
  /// 若不显式 `close`，每次调用都会泄漏一个 `HttpClient`（含其空闲连接池
  /// 与定时器）。一次性客户端必须走这个包装。
  ///
  /// 语义与直接 `await client.get(...)` 完全一致：异常照常抛出，
  /// 只是额外保证 [Dio.close] 被调用。
  static Future<T> withClient<T>(
    Dio Function() create, {
    required Future<T> Function(Dio client) action,
  }) async {
    final dio = create();
    try {
      return await action(dio);
    } finally {
      dio.close(force: true);
    }
  }
}

/// 认证拦截器：自动注入 Token 与 Pica API 签名头
///
/// 第五十九批：此前本拦截器**只**注入 `Authorization` 与几个静态头，
/// 缺少桌面端 `ToolUtil.GetHeader` 生成的 `signature` / `time` / `nonce`
/// 等签名头——这是移动端相对桌面端**真实存在的 P0 缺口**。
/// 现改为按桌面端算法逐请求计算签名。
class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final secureStorage = SecureStorageHolder.instance;

    // 注入 API Token
    final token = await secureStorage.getApiToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    // 第五十九批：注入 Pica API 签名头（对应桌面端 ToolUtil.GetHeader）。
    //
    // 关键点：桌面端参与签名的字符串是
    //   `url.replace(config.Url, "")`  →  "comics?page=1&c=VC"
    // 即**无前导斜杠、带 query string**。而 Dio 的 `options.path` 不含
    // `queryParameters`，所以必须用 `options.uri`（含 query）来还原。
    final signedPath = _signedPathOf(options);
    if (signedPath != null) {
      final method = options.method.toUpperCase();
      final signed = ApiSignature.buildHeaders(
        path: signedPath,
        method: method,
      );
      signed.forEach((key, value) {
        options.headers[key] = value;
      });
    }

    handler.next(options);
  }

  /// 从 RequestOptions 中还原出桌面端参与签名的相对路径。
  ///
  /// 桌面端：`config.Url = "https://picaapi.picacomic.com/"`（带尾部斜杠），
  /// 拼接方式为 `config.Url + "comics?page=1"`，签名时取
  /// `_url.replace(config.Url, "")` → `"comics?page=1"`。
  ///
  /// Dio 侧：`options.uri` 是 baseUrl + path + query 的完整 URI，
  /// `options.path` **不含** `queryParameters`。因此这里用 `options.uri` 还原，
  /// 去掉前导斜杠、保留 query string。
  ///
  /// 归一化逻辑集中在 [ApiSignature.normalizeSignedPath]，它同时处理：
  /// - 同源请求 → 相对路径（无前导斜杠、带 query）
  /// - 代理 base URL 带 path 前缀 → 剥离整个前缀，得到与桌面端一致的相对路径
  /// - 异源请求 → 完整 URL（与桌面端 `replace` 不生效的行为一致）
  String? _signedPathOf(RequestOptions options) {
    final uri = options.uri;
    if (uri.path.isEmpty) return null;
    return ApiSignature.normalizeSignedPath(uri, options.baseUrl);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Token 过期，清理存储
      SecureStorageHolder.instance.clearAll();
    }
    handler.next(err);
  }
}

/// 日志拦截器
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(err);
  }
}
