import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 安全存储封装
/// 用于存储敏感数据：Token、用户信息、代理密码等
class SecureStorage {
  final FlutterSecureStorage _storage;

  SecureStorage(this._storage);

  // Storage Keys
  static const _keyApiToken = 'api_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyUserId = 'user_id';
  static const _keyUserName = 'user_name';
  static const _keyUserEmail = 'user_email';
  static const _keyUserAvatar = 'user_avatar';

  // ================== Token ==================

  /// 获取 API Token
  Future<String?> getApiToken() async {
    return _storage.read(key: _keyApiToken);
  }

  /// 保存 API Token
  Future<void> setApiToken(String token) async {
    await _storage.write(key: _keyApiToken, value: token);
  }

  /// 获取 Refresh Token
  Future<String?> getRefreshToken() async {
    return _storage.read(key: _keyRefreshToken);
  }

  /// 保存 Refresh Token
  Future<void> setRefreshToken(String token) async {
    await _storage.write(key: _keyRefreshToken, value: token);
  }

  /// 清除所有 Token
  Future<void> clearTokens() async {
    await _storage.delete(key: _keyApiToken);
    await _storage.delete(key: _keyRefreshToken);
  }

  // ================== User ==================

  /// 保存用户信息
  Future<void> setUser({
    required String id,
    required String name,
    String? email,
    String? avatar,
  }) async {
    await Future.wait([
      _storage.write(key: _keyUserId, value: id),
      _storage.write(key: _keyUserName, value: name),
      if (email != null) _storage.write(key: _keyUserEmail, value: email),
      if (avatar != null) _storage.write(key: _keyUserAvatar, value: avatar),
    ]);
  }

  /// 获取用户 ID
  Future<String?> getUserId() => _storage.read(key: _keyUserId);

  /// 获取用户名
  Future<String?> getUserName() => _storage.read(key: _keyUserName);

  /// 获取用户邮箱
  Future<String?> getUserEmail() => _storage.read(key: _keyUserEmail);

  /// 获取用户头像
  Future<String?> getUserAvatar() => _storage.read(key: _keyUserAvatar);

  /// 清除用户信息
  Future<void> clearUser() async {
    await Future.wait([
      _storage.delete(key: _keyUserId),
      _storage.delete(key: _keyUserName),
      _storage.delete(key: _keyUserEmail),
      _storage.delete(key: _keyUserAvatar),
    ]);
  }

  // ================== Generic ==================

  /// 读取任意值
  Future<String?> read(String key) => _storage.read(key: key);

  /// 保存任意值
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  /// 删除指定值
  Future<void> delete(String key) => _storage.delete(key: key);

  /// 清除所有
  Future<void> clearAll() => _storage.deleteAll();

  /// 批量读取
  Future<Map<String, String>> readAll() => _storage.readAll();
}

/// 全局访问点（在 main.dart 中初始化）
class SecureStorageHolder {
  static SecureStorage? _instance;

  static SecureStorage get instance {
    if (_instance == null) {
      throw StateError('SecureStorage not initialized. Call main() first.');
    }
    return _instance!;
  }

  static set instance(SecureStorage value) {
    _instance = value;
  }
}
