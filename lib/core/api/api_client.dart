import 'package:dio/dio.dart';

import '../../shared/constants/api_constants.dart';
import '../storage/secure_storage.dart';
import '../storage/settings_storage.dart';

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

    // 配置代理（需要通过 ProxySelector 方式，这里简化处理）
    // 移除旧拦截器，重新添加
    _dio.interceptors.clear();
    _dio.interceptors.add(_AuthInterceptor());
    _dio.interceptors.add(_LoggingInterceptor());

    return _dio;
  }
}

/// 认证拦截器：自动注入 Token
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

    // 注入设备标识
    options.headers['api-key'] =
        'C69BAF41DA5ABD1FF2C0A1D2C0A1D2C0A1D2C0A1D2C0A1D2C0A1D2C0A1D2C0A';
    options.headers['app-version'] = '2.4.1.2.3';
    options.headers['app-build'] = '325';
    options.headers['User-Agent'] = 'PicacgAndroid/2.4.1.2.3';
    options.headers['Content-Type'] = 'application/json';

    handler.next(options);
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
