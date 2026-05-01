import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app.dart';
import 'core/db/database.dart';
import 'core/storage/secure_storage.dart';
import 'core/storage/settings_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化安全存储
  const secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  SecureStorageHolder.instance = SecureStorage(secureStorage);

  // 初始化设置存储
  final settingsStorage = SettingsStorage(secureStorage);
  SettingsStorageHolder.instance = settingsStorage;

  // 预加载同步缓存
  final cached = await secureStorage.readAll();
  SettingsStorage.populateCache(cached);

  // 初始化数据库
  final db = AppDatabase();
  await db.initialize();
  DatabaseHolder.instance = db;

  runApp(
    const ProviderScope(
      child: PicacgApp(),
    ),
  );
}

/// 数据库全局访问器
class DatabaseHolder {
  static AppDatabase? _instance;

  static AppDatabase get instance {
    if (_instance == null) {
      throw StateError('Database not initialized. Call main() first.');
    }
    return _instance!;
  }

  static set instance(AppDatabase value) {
    _instance = value;
  }
}
