import 'dart:io';

import 'package:dio/dio.dart';

import '../../shared/constants/api_constants.dart';
import '../storage/secure_storage.dart';
import '../storage/settings_storage.dart';
import 'api_endpoints.dart';

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

  /// 获取配置后的 Dio 实例
  /// 每次调用都会根据当前设置重新配置代理和 Base URL
  static Dio get instance {
    final settings = SettingsStorage.instance;
    final baseUrl = settings.getApiBaseUrlSync() ?? ApiEndpoints.defaultBaseUrl;

    _dio.options.baseUrl = baseUrl;

    // 配置代理
    _configureProxy(settings);

    // 移除旧拦截器，重新添加
    _dio.interceptors.clear();
    _dio.interceptors.add(_AuthInterceptor());
    _dio.interceptors.add(_LoggingInterceptor());

    return _dio;
  }

  /// 配置代理
  static void _configureProxy(SettingsStorage settings) {
    final proxyConfig = settings.getProxyConfigSync();

    if (proxyConfig == null || proxyConfig.type == ProxyType.none) {
      // 不使用代理，清除系统代理
      _dio.httpClientAdapter as HttpClientAdapter;
      return;
    }

    // Dio 使用系统代理设置
    // 在移动端，需要通过自定义 HttpClientAdapter 来设置代理
    // 这里通过环境变量或平台特定方式配置
    if (Platform.isAndroid || Platform.isIOS) {
      // 移动端使用 ProxySelector
      _dio.options.extra['proxy'] = {
        'type': proxyConfig.type == ProxyType.socks5 ? 'socks5' : 'http',
        'host': proxyConfig.host,
        'port': proxyConfig.port,
        'username': proxyConfig.username,
        'password': proxyConfig.password,
      };
    }
  }
}

/// 认证拦截器：自动注入 Token
class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final secureStorage = SecureStorage.instance;

    // 注入 API Token
    final token = await secureStorage.getApiToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    // 注入设备标识
    options.headers['api-key'] = 'C69BAF41DA5ABD1FF2C0A1D2C0A1D2C0A1D2C0A1D2C0A1D2C0A1D2C0A1D2C0A';
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
      SecureStorage.instance.clearAll();
    }
    handler.next(err);
  }
}

/// 日志拦截器
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // TODO: 发布时关闭日志
    // log('🌐 REQUEST[${options.method}] => PATH: ${options.path}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // log('🌐 RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // log('🌐 ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}');
    handler.next(err);
  }
}
