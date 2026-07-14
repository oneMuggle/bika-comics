import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picacg_flutter/core/storage/settings_storage.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    SettingsStorage.populateCache(const {});
  });

  tearDown(() {
    SettingsStorage.populateCache(const {});
  });

  group('SettingsStorage 自动签到', () {
    test('未配置时默认开启，与桌面端一致', () async {
      final storage = SettingsStorage(const FlutterSecureStorage());

      expect(storage.getAutoSignSync(), isTrue);
      expect(await storage.getAutoSign(), isTrue);
    });

    test('setAutoSign 同步更新缓存并持久化', () async {
      final storage = SettingsStorage(const FlutterSecureStorage());

      await storage.setAutoSign(false);
      expect(storage.getAutoSignSync(), isFalse);
      expect(await storage.getAutoSign(), isFalse);

      await storage.setAutoSign(true);
      expect(storage.getAutoSignSync(), isTrue);
      expect(await storage.getAutoSign(), isTrue);
    });

    test('populateCache 能恢复显式关闭状态', () {
      SettingsStorage.populateCache(const {'auto_sign': 'false'});
      final storage = SettingsStorage(const FlutterSecureStorage());

      expect(storage.getAutoSignSync(), isFalse);
    });
  });
}
