import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../utils/proxy_selector.dart';

// Settings Storage Keys
const _keyApiBaseUrl = 'api_base_url';
const _keyProxyConfig = 'proxy_config';
const _keyThemeMode = 'theme_mode';
const _keyReaderDirection = 'reader_direction';
const _keyImageQuality = 'image_quality';
const _keyAutoNextEpisode = 'auto_next_episode';
const _keyDownloadPath = 'download_path';
const _keyForbidWords = 'forbid_words';
const _keyForbidTitle = 'forbid_title';
const _keyForbidTag = 'forbid_tag';
const _keyForbidCategory = 'forbid_category';
const _keyChatSendAction = 'chat_send_action';
const _keyAutoSign = 'auto_sign'; // 第二十四批：登录后自动签到（桌面 Setting.AutoSign，默认 true）

/// 设置存储（非敏感设置）
class SettingsStorage {
  // We share the same secure storage for convenience
  final FlutterSecureStorage _storage;

  SettingsStorage(this._storage);

  // ================== API Base URL ==================

  String? getApiBaseUrlSync() => _syncRead(_keyApiBaseUrl);

  Future<String?> getApiBaseUrl() => _storage.read(key: _keyApiBaseUrl);

  Future<void> setApiBaseUrl(String url) =>
      _storage.write(key: _keyApiBaseUrl, value: url);

  // ================== Proxy Config ==================

  ProxyConfig? getProxyConfigSync() {
    final json = _syncRead(_keyProxyConfig);
    if (json == null) return null;
    return ProxyConfig.fromJson(jsonDecode(json));
  }

  Future<ProxyConfig?> getProxyConfig() async {
    final json = await _storage.read(key: _keyProxyConfig);
    if (json == null) return null;
    return ProxyConfig.fromJson(jsonDecode(json));
  }

  Future<void> setProxyConfig(ProxyConfig config) =>
      _storage.write(key: _keyProxyConfig, value: jsonEncode(config.toJson()));

  Future<void> clearProxyConfig() => _storage.delete(key: _keyProxyConfig);

  // ================== Theme ==================

  ThemeMode getThemeModeSync() {
    final value = _syncRead(_keyThemeMode);
    return _parseThemeMode(value);
  }

  Future<ThemeMode> getThemeMode() async {
    final value = await _storage.read(key: _keyThemeMode);
    return _parseThemeMode(value);
  }

  Future<void> setThemeMode(ThemeMode mode) {
    return _storage.write(key: _keyThemeMode, value: mode.name);
  }

  ThemeMode _parseThemeMode(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  // ================== Reader Settings ==================

  /// 阅读方向：0=左到右，1=右到左，2=从上到下
  int getReaderDirectionSync() {
    final v = _syncRead(_keyReaderDirection);
    return int.tryParse(v ?? '0') ?? 0;
  }

  Future<int> getReaderDirection() async {
    final v = await _storage.read(key: _keyReaderDirection);
    return int.tryParse(v ?? '0') ?? 0;
  }

  Future<void> setReaderDirection(int direction) =>
      _storage.write(key: _keyReaderDirection, value: direction.toString());

  /// 图片质量：0=低，1=中，2=高
  int getImageQualitySync() {
    final v = _syncRead(_keyImageQuality);
    return int.tryParse(v ?? '2') ?? 2;
  }

  Future<int> getImageQuality() async {
    final v = await _storage.read(key: _keyImageQuality);
    return int.tryParse(v ?? '2') ?? 2;
  }

  Future<void> setImageQuality(int quality) =>
      _storage.write(key: _keyImageQuality, value: quality.toString());

  /// 自动加载下一章节
  bool getAutoNextEpisodeSync() {
    final v = _syncRead(_keyAutoNextEpisode);
    return v == 'true';
  }

  Future<bool> getAutoNextEpisode() async {
    final v = await _storage.read(key: _keyAutoNextEpisode);
    return v == 'true';
  }

  Future<void> setAutoNextEpisode(bool value) =>
      _storage.write(key: _keyAutoNextEpisode, value: value.toString());

  // ================== Download ==================

  Future<String?> getDownloadPath() => _storage.read(key: _keyDownloadPath);

  Future<void> setDownloadPath(String path) =>
      _storage.write(key: _keyDownloadPath, value: path);

  // ================== 搜索屏蔽词 (P2 - 2026-06-06) ==================

  /// 屏蔽词列表（JSON 编码的字符串数组）
  /// 对应桌面端 Setting.ForbidWords / Setting.AddForbidWords
  Future<List<String>> getForbidWords() async {
    final json = await _storage.read(key: _keyForbidWords);
    if (json == null || json.isEmpty) return <String>[];
    try {
      final list = jsonDecode(json) as List;
      return list.map((e) => e.toString()).toList();
    } catch (_) {
      return <String>[];
    }
  }

  Future<void> setForbidWords(List<String> words) =>
      _storage.write(key: _keyForbidWords, value: jsonEncode(words));

  /// 是否按标题屏蔽
  Future<bool> getIsForbidTitle() async {
    final v = await _storage.read(key: _keyForbidTitle);
    return v == 'true';
  }

  Future<void> setIsForbidTitle(bool value) =>
      _storage.write(key: _keyForbidTitle, value: value.toString());

  /// 是否按 Tag 屏蔽
  Future<bool> getIsForbidTag() async {
    final v = await _storage.read(key: _keyForbidTag);
    return v == 'true';
  }

  Future<void> setIsForbidTag(bool value) =>
      _storage.write(key: _keyForbidTag, value: value.toString());

  /// 是否按分类屏蔽
  Future<bool> getIsForbidCategory() async {
    final v = await _storage.read(key: _keyForbidCategory);
    return v == 'true';
  }

  Future<void> setIsForbidCategory(bool value) =>
      _storage.write(key: _keyForbidCategory, value: value.toString());

  // ================== 聊天室 (P2 - 2026-06-06) ==================

  /// 发送方式：0=Ctrl+Enter 发送，1=Enter 发送
  /// 对应桌面端 Setting.ChatSendAction
  Future<int> getChatSendAction() async {
    final v = await _storage.read(key: _keyChatSendAction);
    return int.tryParse(v ?? '0') ?? 0;
  }

  Future<void> setChatSendAction(int action) =>
      _storage.write(key: _keyChatSendAction, value: action.toString());

  // ================== 自动签到 (第二十四批 - 2026-07-15) ==================

  /// 登录成功后是否自动签到（POST /users/punch-in）
  /// 对应桌面端 Setting.AutoSign（config/setting.py 默认 1 = true）
  /// 默认值 true：与桌面端行为保持一致；用户首次启动即生效。
  bool getAutoSignSync() {
    final v = _syncRead(_keyAutoSign);
    // 缺失等价于首次启动 → 默认 true（与桌面默认一致）。
    if (v == null) return true;
    return v == 'true';
  }

  Future<bool> getAutoSign() async {
    final v = await _storage.read(key: _keyAutoSign);
    if (v == null) return true;
    return v == 'true';
  }

  /// 同时写入持久化存储和同步缓存（保持现有 `get*Sync()` 设计契约）。
  Future<void> setAutoSign(bool value) async {
    _cache[_keyAutoSign] = value.toString();
    await _storage.write(key: _keyAutoSign, value: value.toString());
  }

  // ================== Helpers ==================

  String? _syncRead(String key) {
    // Synchronous read from cached values map
    return _cache[key];
  }

  static final Map<String, String> _cache = {};

  static void populateCache(Map<String, String> values) {
    _cache.clear();
    _cache.addAll(values);
  }
}

/// SettingsStorage 全局访问器
class SettingsStorageHolder {
  static SettingsStorage? _instance;

  static SettingsStorage get instance {
    if (_instance == null) {
      throw StateError('SettingsStorage not initialized. Call main() first.');
    }
    return _instance!;
  }

  static set instance(SettingsStorage value) {
    _instance = value;
  }
}

/// SettingsStorage Riverpod Provider
final settingsStorageProvider = Provider<SettingsStorage>((ref) {
  const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  return SettingsStorage(storage);
});
