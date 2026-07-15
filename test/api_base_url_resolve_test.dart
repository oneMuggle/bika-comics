import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picacg_flutter/core/api/api_client.dart';
import 'package:picacg_flutter/core/storage/settings_storage.dart';
import 'package:picacg_flutter/shared/constants/api_constants.dart';

void main() {
  group('ApiEndpoints.isValidBaseUrl', () {
    test('接受 https 与 http URL（带或不带末尾斜杠）', () {
      expect(
        ApiEndpoints.isValidBaseUrl('https://picaapi.picacomic.com'),
        isTrue,
      );
      expect(
        ApiEndpoints.isValidBaseUrl('http://example.com/'),
        isTrue,
      );
      expect(
        ApiEndpoints.isValidBaseUrl('  https://api.example.com  '),
        isTrue,
        reason: '允许首尾空白',
      );
    });

    test('拒绝空值、null 与纯空白字符串', () {
      expect(ApiEndpoints.isValidBaseUrl(null), isFalse);
      expect(ApiEndpoints.isValidBaseUrl(''), isFalse);
      expect(ApiEndpoints.isValidBaseUrl('   '), isFalse);
    });

    test('拒绝非法 scheme', () {
      expect(ApiEndpoints.isValidBaseUrl('ftp://example.com'), isFalse);
      expect(ApiEndpoints.isValidBaseUrl('file:///etc/passwd'), isFalse);
      expect(ApiEndpoints.isValidBaseUrl('javascript:alert(1)'), isFalse);
      expect(ApiEndpoints.isValidBaseUrl('example.com'), isFalse,
          reason: '缺少 scheme');
    });

    test('拒绝无 host 的 URL', () {
      expect(ApiEndpoints.isValidBaseUrl('https://'), isFalse);
      expect(ApiEndpoints.isValidBaseUrl('http:///path'), isFalse);
    });
  });

  group('ApiEndpoints.normalizeBaseUrl', () {
    test('去除末尾斜杠', () {
      expect(
        ApiEndpoints.normalizeBaseUrl('https://example.com/'),
        'https://example.com',
      );
      expect(
        ApiEndpoints.normalizeBaseUrl('https://example.com///'),
        'https://example.com',
      );
    });

    test('去除首尾空白', () {
      expect(
        ApiEndpoints.normalizeBaseUrl('  https://example.com  '),
        'https://example.com',
      );
    });
  });

  group('ApiClient.resolveBaseUrl', () {
    tearDown(() {
      // 重置 holder 到一个新实例并清空缓存，避免污染其它测试。
      // （SettingsStorageHolder 强制非 null，无法直接置空。）
      SettingsStorageHolder.instance =
          SettingsStorage(const FlutterSecureStorage());
      SettingsStorage.populateCache({});
    });

    test('未初始化 SettingsStorageHolder 时回退到默认值', () {
      // 这里不需要主动 set null：populateCache 不会创建 holder；ApiClient.resolveBaseUrl
      // 在 holder 未初始化时会捕获 StateError 并回退。
      expect(
        ApiClient.resolveBaseUrl(),
        ApiEndpoints.defaultBaseUrl,
      );
    });

    test('未配置自定义地址时回退到默认值', () {
      final storage = SettingsStorage(const FlutterSecureStorage());
      SettingsStorageHolder.instance = storage;
      SettingsStorage.populateCache({});
      expect(
        ApiClient.resolveBaseUrl(),
        ApiEndpoints.defaultBaseUrl,
      );
    });

    test('已配置合法地址时优先返回自定义地址', () {
      final storage = SettingsStorage(const FlutterSecureStorage());
      SettingsStorageHolder.instance = storage;
      SettingsStorage.populateCache({
        'api_base_url': 'https://my-mirror.example.com',
      });
      expect(
        ApiClient.resolveBaseUrl(),
        'https://my-mirror.example.com',
      );
    });

    test('已配置但非法地址时回退到默认值（不抛异常）', () {
      final storage = SettingsStorage(const FlutterSecureStorage());
      SettingsStorageHolder.instance = storage;
      SettingsStorage.populateCache({
        'api_base_url': 'not a url',
      });
      expect(
        ApiClient.resolveBaseUrl(),
        ApiEndpoints.defaultBaseUrl,
      );
    });
  });
}
