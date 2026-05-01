import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 代理配置模型
enum ProxyType { none, socks5, http }

class ProxyConfig {
  final ProxyType type;
  final String host;
  final int port;
  final String? username;
  final String? password;

  const ProxyConfig({
    required this.type,
    required this.host,
    required this.port,
    this.username,
    this.password,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'host': host,
        'port': port,
        'username': username,
        'password': password,
      };

  factory ProxyConfig.fromJson(Map<String, dynamic> json) => ProxyConfig(
        type: ProxyType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => ProxyType.none,
        ),
        host: json['host'] ?? '',
        port: json['port'] ?? 0,
        username: json['username'],
        password: json['password'],
      );

  /// SOCKS5 代理 URI
  String? get proxyUri {
    if (type == ProxyType.none) return null;
    final auth = (username != null && password != null)
        ? '$username:$password@'
        : '';
    return '${type == ProxyType.socks5 ? 'socks5' : 'http'}://$auth$host:$port';
  }
}

/// 代理选择器工具类
class ProxySelector {
  ProxySelector._();

  /// 应用代理配置到 Dio（平台特定实现）
  static void applyToDio(Dio dio, ProxyConfig? config) {
    if (config == null || config.type == ProxyType.none) {
      _clearProxy(dio);
      return;
    }

    if (Platform.isAndroid || Platform.isIOS) {
      // 移动端通过 extra 参数传递代理配置
      dio.options.extra['proxy'] = {
        'type': config.type == ProxyType.socks5 ? 'socks5' : 'http',
        'host': config.host,
        'port': config.port,
        if (config.username != null) 'username': config.username,
        if (config.password != null) 'password': config.password,
      };
    }
  }

  static void _clearProxy(Dio dio) {
    dio.options.extra.remove('proxy');
  }
}
