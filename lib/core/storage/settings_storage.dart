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

  // ================== Helpers ==================

  String? _syncRead(String key) {
    // Synchronous read using readAll
    // FlutterSecureStorage doesn't support sync read natively
    // For sync access we cache values - this is a simplified approach
    return null; // Will be loaded async
  }
}

/// SettingsStorage Riverpod Provider
final settingsStorageProvider = Provider<SettingsStorage>((ref) {
  const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  return SettingsStorage(storage);
});
