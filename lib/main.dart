import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app.dart';
import 'core/db/database.dart';
import 'core/storage/secure_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化安全存储
  const secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  SecureStorageHolder.instance = SecureStorage(secureStorage);

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
  static AppDatabase instance = throw UninitializedError('Database not initialized');
}

/// 安全存储全局访问器
class SecureStorageHolder {
  static SecureStorage instance = throw UninitializedError('SecureStorage not initialized');
}
