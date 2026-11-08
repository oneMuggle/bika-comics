import 'package:flutter_test/flutter_test.dart';
import 'package:picacg_flutter/core/api/api_signature.dart';

/// 已知答案测试（KAT）— 第五十九批新增
///
/// 本文件中的所有期望值均由**桌面端源码本身**导出：
/// 脚本用 Python `ast` 从 `picacg-qt-temp/src/tools/tool.py` 中原样提取
/// `ToolUtil` 类（`GetHeader` / `__ConFromNative` / `__SigFromNative` /
/// `HashKey`），固定 `time` 与 `nonce` 后生成签名向量。
///
/// 因此这些断言验证的是「Dart 实现 == 桌面端实现」，而不是
/// 「Dart 实现 == 我自己写的 Dart 实现」——这正是本测试存在的意义：
/// 防止未来重构悄悄改变签名算法。
///
/// 第五十九批修复：本文件原先**缺少 `main()` 方法**，导致 `flutter test`
/// 报 "Missing definition of `main` method" 而整文件加载失败。
void main() {
  // 固定时钟与 nonce，保证签名可复现
  const String fixedTime = '1767225600'; // 2026-01-01T00:00:00Z
  const String fixedNonce = '0123456789abcdef0123456789abcdef';

  group('应用密钥', () {
    test('与桌面端 ToolUtil.__SigFromNative() 完全一致（63 字符）', () {
      expect(ApiSignature.appSecret.length, 63);
      expect(
        ApiSignature.appSecret,
        r'~d}$Q7$eIni=V)9\RK/P.RM4;9[7|@/CA}b~OW!3?EV`:<>M7pddUBL5n|0/*Cn',
      );
    });

    test('apiKey 与桌面端 config.ApiKey 一致', () {
      expect(ApiSignature.apiKey, 'C69BAF41DA5ABD1FFEDC6D2FEA56B');
    });
  });

  group('buildSignedSource 与桌面端 __ConFromNative 一致', () {
    test('GET comics?page=1', () {
      final src = ApiSignature.buildSignedSource(
        path: 'comics?page=1',
        time: fixedTime,
        nonce: fixedNonce,
        method: 'GET',
      );
      expect(
        src,
        'comics?page=117672256000123456789abcdef0123456789abcdef'
        'GETC69BAF41DA5ABD1FFEDC6D2FEA56B',
      );
    });

    test('POST auth/sign-in', () {
      final src = ApiSignature.buildSignedSource(
        path: 'auth/sign-in',
        time: fixedTime,
        nonce: fixedNonce,
        method: 'POST',
      );
      expect(
        src,
        'auth/sign-in17672256000123456789abcdef0123456789abcdef'
        'POSTC69BAF41DA5ABD1FFEDC6D2FEA56B',
      );
    });
  });

  group('签名与桌面端 GetHeader 完全一致（已知答案向量）', () {
    void expectVector({
      required String path,
      required String method,
      required String expectedSignature,
    }) {
      final headers = ApiSignature.buildHeaders(
        path: path,
        method: method,
        time: fixedTime,
        nonce: fixedNonce,
      );
      expect(
        headers['signature'],
        expectedSignature,
        reason: '签名不匹配: $method $path',
      );
    }

    test('GET comics?page=1', () {
      expectVector(
        path: 'comics?page=1',
        method: 'GET',
        expectedSignature:
            '3faa796b8ecb2751d128e3e6e581e8c06716ad3be61ca4efab82df255289ca9c',
      );
    });

    test('GET comics', () {
      expectVector(
        path: 'comics',
        method: 'GET',
        expectedSignature:
            '36602bcfc33987de97c21cfdf93882d1ae90ffb7bdaac232b7e33329a68bce69',
      );
    });

    test('GET comics?page=2', () {
      expectVector(
        path: 'comics?page=2',
        method: 'GET',
        expectedSignature:
            '5da76b4b2b76d6669abde16187a94ef6739535f2d50e2a4ac0a9b2028031f4ff',
      );
    });

    test('GET categories', () {
      expectVector(
        path: 'categories',
        method: 'GET',
        expectedSignature:
            'e66394cd1541c344f309099222af5212ec5679d586c7e20bbaa894185429a549',
      );
    });

    test('GET comics/123/eps', () {
      expectVector(
        path: 'comics/123/eps',
        method: 'GET',
        expectedSignature:
            'c83778eac5c3a2013a504842e0baa4f340e129d16bf93149c9ad566a76586487',
      );
    });

    test('POST auth/sign-in', () {
      expectVector(
        path: 'auth/sign-in',
        method: 'POST',
        expectedSignature:
            '0d2ddea613d767b2c8b3bb867adb6ed6634d47d2b7cd292b7d3f25950aef055a',
      );
    });

    test('POST comics/123/favourite', () {
      expectVector(
        path: 'comics/123/favourite',
        method: 'POST',
        expectedSignature:
            '1223924e0043e444b2939ef366a6e7fb6d88ce67a173c1081911fde2580056b2',
      );
    });

    test('PUT users/avatar', () {
      expectVector(
        path: 'users/avatar',
        method: 'PUT',
        expectedSignature:
            'adeee520f0ac2ec1847b77f046aaf21722b0cc5efe73c9ba10dc407fa0cb26d4',
      );
    });
  });

  group('buildHeaders 输出完整的桌面端请求头集合', () {
    test('包含桌面端 GetHeader 的全部 13 个头', () {
      final headers = ApiSignature.buildHeaders(
        path: 'comics',
        method: 'GET',
        time: fixedTime,
        nonce: fixedNonce,
      );
      const expectedKeys = {
        'api-key',
        'accept',
        'app-channel',
        'time',
        'app-uuid',
        'nonce',
        'signature',
        'app-version',
        'image-quality',
        'app-platform',
        'app-build-version',
        'user-agent',
        'version',
      };
      for (final key in expectedKeys) {
        expect(headers.containsKey(key), isTrue, reason: '缺少请求头: $key');
      }
      expect(headers.keys.toSet(), expectedKeys);
    });

    test('各头的值与桌面端 config 一致', () {
      final headers = ApiSignature.buildHeaders(
        path: 'comics',
        method: 'GET',
        time: fixedTime,
        nonce: fixedNonce,
      );
      expect(headers['api-key'], 'C69BAF41DA5ABD1FFEDC6D2FEA56B');
      expect(headers['accept'], 'application/vnd.picacomic.com.v1+json');
      expect(headers['app-channel'], '3');
      expect(headers['time'], fixedTime);
      expect(headers['app-uuid'], 'defaultUuid');
      expect(headers['nonce'], fixedNonce);
      expect(headers['app-version'], '2.2.1.3.3.4');
      expect(headers['image-quality'], 'original');
      expect(headers['app-platform'], 'android');
      expect(headers['app-build-version'], '45');
      expect(headers['user-agent'], 'okhttp/3.8.1');
      expect(headers['version'], 'v1.5.4');
    });

    test('POST 时附带 Content-Type', () {
      final headers = ApiSignature.buildHeaders(
        path: 'auth/sign-in',
        method: 'POST',
        time: fixedTime,
        nonce: fixedNonce,
      );
      expect(headers['Content-Type'], 'application/json; charset=UTF-8');
    });

    test('PUT 时附带 Content-Type', () {
      final headers = ApiSignature.buildHeaders(
        path: 'users/avatar',
        method: 'PUT',
        time: fixedTime,
        nonce: fixedNonce,
      );
      expect(headers['Content-Type'], 'application/json; charset=UTF-8');
    });

    test('GET 时不附带 Content-Type（与桌面端一致）', () {
      final headers = ApiSignature.buildHeaders(
        path: 'comics',
        method: 'GET',
        time: fixedTime,
        nonce: fixedNonce,
      );
      expect(headers.containsKey('Content-Type'), isFalse);
    });

    test('DELETE 时不附带 Content-Type（与桌面端一致）', () {
      final headers = ApiSignature.buildHeaders(
        path: 'comics/123/favourite',
        method: 'DELETE',
        time: fixedTime,
        nonce: fixedNonce,
      );
      expect(headers.containsKey('Content-Type'), isFalse);
    });
  });

  group('nonce 与时间戳', () {
    test('generateNonce 产生 32 位十六进制', () {
      final nonce = ApiSignature.generateNonce();
      expect(nonce.length, 32);
      expect(RegExp(r'^[0-9a-f]{32}$').hasMatch(nonce), isTrue);
    });

    test('currentTimestamp 是秒级时间戳', () {
      final ts = int.tryParse(ApiSignature.currentTimestamp());
      expect(ts, isNotNull);
      expect(ts!, greaterThan(1700000000));
    });
  });

  group('normalizeSignedPath 与桌面端 url.replace(config.Url, "") 一致', () {
    // 桌面端 config.Url = "https://picaapi.picacomic.com/"（带尾部斜杠）
    const baseUrl = 'https://picaapi.picacomic.com';

    test('去掉前导斜杠并保留 query string', () {
      final uri = Uri.parse(
        'https://picaapi.picacomic.com/comics?page=1&c=VC&s=',
      );
      expect(
        ApiSignature.normalizeSignedPath(uri, baseUrl),
        'comics?page=1&c=VC&s=',
      );
    });

    test('无 query 时只保留 path', () {
      final uri = Uri.parse('https://picaapi.picacomic.com/categories');
      expect(ApiSignature.normalizeSignedPath(uri, baseUrl), 'categories');
    });

    test('嵌套路径去掉前导斜杠', () {
      final uri = Uri.parse(
        'https://picaapi.picacomic.com/comments/abc/childrens?page=2',
      );
      expect(
        ApiSignature.normalizeSignedPath(uri, baseUrl),
        'comments/abc/childrens?page=2',
      );
    });

    // 第五十九批：代理 base URL 带 path 前缀时，必须剥离**整个**前缀，
    // 才能得到与桌面端一致的相对路径（桌面端先按 config.Url 签名，
    // 再在 server.py 里改写 host 走代理）。
    test('代理 base URL 带 path 前缀时剥离整个前缀', () {
      const proxyBase = 'https://bika-api.jpacg.cc/picaapi.picacomic.com';
      final uri = Uri.parse(
        'https://bika-api.jpacg.cc/picaapi.picacomic.com/comics?page=1',
      );
      expect(
        ApiSignature.normalizeSignedPath(uri, proxyBase),
        'comics?page=1',
      );
    });

    test('代理 base URL 带末尾斜杠同样正确', () {
      const proxyBase = 'https://bika-api.jpacg.cc/picaapi.picacomic.com/';
      final uri = Uri.parse(
        'https://bika-api.jpacg.cc/picaapi.picacomic.com/comics?page=1',
      );
      expect(
        ApiSignature.normalizeSignedPath(uri, proxyBase),
        'comics?page=1',
      );
    });

    // 第五十九批修复：Uri.replace(fragment: '') 会残留一个空的 fragment，
    // 导致异源签名对象以 "#" 结尾，与桌面端不一致。
    test('异源请求的签名对象不含空 fragment 产生的 "#"', () {
      final uri = Uri.parse('https://third.party.example.com/games?page=1');
      final signed = ApiSignature.normalizeSignedPath(uri, baseUrl);
      expect(signed, 'https://third.party.example.com/games?page=1');
      expect(signed, isNot(contains('#')));
    });

    test('异源请求带真实 fragment 时同样剥离', () {
      final uri = Uri.parse('https://third.party.example.com/games#frag');
      final signed = ApiSignature.normalizeSignedPath(uri, baseUrl);
      expect(signed, 'https://third.party.example.com/games');
      expect(signed, isNot(contains('#')));
    });
  });
}
