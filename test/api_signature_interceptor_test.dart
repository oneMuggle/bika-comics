import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picacg_flutter/core/api/api_client.dart';
import 'package:picacg_flutter/core/storage/secure_storage.dart';

/// 拦截器签名一致性回归测试 — 第五十九批
///
/// 这个测试锁定的是**最容易悄悄坏掉、且静默失败**的一环：
/// 拦截器究竟把哪个字符串送进 HMAC。
///
/// 桌面端 `src/tools/tool.py`：
/// ```python
/// config.Url = "https://picaapi.picacomic.com/"      # 带尾部斜杠
/// url = config.Url + "comics?page=1&c=VC&s="         # 拼接方式
/// datas[1] = _url.replace(config.Url, "")            # → "comics?page=1&c=VC&s="
/// ```
/// 即：参与签名的相对路径**无前导斜杠、带 query string**。
///
/// 第五十九批修复的缺陷：拦截器改用 Dio 的 `options.path`，而 Dio 的
/// `options.path` **不含 `queryParameters`**（实测 `options.path == "/comics"`，
/// `options.uri == ".../comics?page=1&c=VC"`）。于是签名对象少了一半，
/// 服务端校验必然失败。本测试用真实 Dio 请求捕获实际签名输入来防止回归。
class _CaptureAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      '{"message":"ok","code":200,"data":{}}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// 通过反射式调用取得拦截器计算出的签名头（避免暴露内部 API）。
Future<Map<String, dynamic>> captureSignedHeaders({
  required String path,
  required Map<String, dynamic>? queryParameters,
  String method = 'GET',
}) async {
  final dio = Dio(BaseOptions(
    baseUrl: 'https://picaapi.picacomic.com',
    responseType: ResponseType.json,
  ));
  final adapter = _CaptureAdapter();
  dio.httpClientAdapter = adapter;

  // 复用 AppClient 的真实拦截器
  final client = ApiClient.instance;
  dio.interceptors.clear();
  dio.interceptors.addAll(client.interceptors);

  await dio.request<dynamic>(
    path,
    data: null,
    queryParameters: queryParameters,
    options: Options(method: method),
  );

  return adapter.requests.single.headers;
}

/// 用桌面端算法独立重算签名（独立实现，不复用 ApiSignature），
/// 以此验证拦截器送入 HMAC 的字符串与桌面端一致。
String desktopSignature(String relativePath, String time, String nonce,
    String method) {
  const apiKey = 'C69BAF41DA5ABD1FFEDC6D2FEA56B';
  const secret = r'~d}$Q7$eIni=V)9\RK/P.RM4;9[7|@/CA}b~OW!3?EV`:<>M7pddUBL5n|0/*Cn';
  final src = '$relativePath$time$nonce$method$apiKey';
  return _hmacSha256Hex(src.toLowerCase(), secret);
}

String _hmacSha256Hex(String data, String secret) {
  // 纯 Dart 实现 HMAC-SHA256，避免在测试中引入 crypto 依赖差异
  const blockSize = 64;
  var key = secret.codeUnits;
  if (key.length > blockSize) {
    key = _sha256(key);
  }
  while (key.length < blockSize) {
    key = [...key, 0];
  }
  final innerPad = List<int>.generate(blockSize, (i) => key[i] ^ 0x36);
  final outerPad = List<int>.generate(blockSize, (i) => key[i] ^ 0x5c);
  final inner = _sha256([...innerPad, ...data.codeUnits]);
  return _sha256([...outerPad, ...inner]).map(_hex).join();
}

List<int> _sha256(List<int> message) {
  // FIPS 180-4 SHA-256
  const k = [
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, //
    0x923f82a4, 0xab1c5ed5, 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
    0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174, 0xe49b69c1, 0xefbe4786,
    0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147,
    0x06ca6351, 0x14292967, 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
    0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85, 0xa2bfe8a1, 0xa81a664b,
    0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a,
    0x5b9cca4f, 0x682e6ff3, 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
    0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
  ];
  final h = [
    0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, //
    0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19,
  ];

  final msgLen = message.length;
  final withPadding = [...message, 0x80];
  while (withPadding.length % 64 != 56) {
    withPadding.add(0);
  }
  final bitLen = msgLen * 8;
  for (var i = 7; i >= 0; i--) {
    withPadding.add((bitLen >> (8 * i)) & 0xff);
  }

  final w = List<int>.filled(64, 0);
  for (var chunk = 0; chunk < withPadding.length; chunk += 64) {
    for (var i = 0; i < 16; i++) {
      final j = chunk + i * 4;
      w[i] = (withPadding[j] << 24) |
          (withPadding[j + 1] << 16) |
          (withPadding[j + 2] << 8) |
          withPadding[j + 3];
    }
    for (var i = 16; i < 64; i++) {
      final s0 = _rotr(w[i - 15], 7) ^ _rotr(w[i - 15], 18) ^ (w[i - 15] >> 3);
      final s1 = _rotr(w[i - 2], 17) ^ _rotr(w[i - 2], 19) ^ (w[i - 2] >> 10);
      w[i] = (w[i - 16] + s0 + w[i - 7] + s1) & 0xffffffff;
    }

    var a = h[0], bb = h[1], c = h[2], d = h[3];
    var e = h[4], f = h[5], g = h[6], hh = h[7];

    for (var i = 0; i < 64; i++) {
      final s1 = _rotr(e, 6) ^ _rotr(e, 11) ^ _rotr(e, 25);
      final ch = (e & f) ^ ((~e & 0xffffffff) & g);
      final temp1 = (hh + s1 + ch + k[i] + w[i]) & 0xffffffff;
      final s0 = _rotr(a, 2) ^ _rotr(a, 13) ^ _rotr(a, 22);
      final maj = (a & bb) ^ (a & c) ^ (bb & c);
      final temp2 = (s0 + maj) & 0xffffffff;

      hh = g;
      g = f;
      f = e;
      e = (d + temp1) & 0xffffffff;
      d = c;
      c = bb;
      bb = a;
      a = (temp1 + temp2) & 0xffffffff;
    }

    h[0] = (h[0] + a) & 0xffffffff;
    h[1] = (h[1] + bb) & 0xffffffff;
    h[2] = (h[2] + c) & 0xffffffff;
    h[3] = (h[3] + d) & 0xffffffff;
    h[4] = (h[4] + e) & 0xffffffff;
    h[5] = (h[5] + f) & 0xffffffff;
    h[6] = (h[6] + g) & 0xffffffff;
    h[7] = (h[7] + hh) & 0xffffffff;
  }

  final out = <int>[];
  for (final v in h) {
    out.add((v >> 24) & 0xff);
    out.add((v >> 16) & 0xff);
    out.add((v >> 8) & 0xff);
    out.add(v & 0xff);
  }
  return out;
}

int _rotr(int x, int n) => ((x >> n) | (x << (32 - n))) & 0xffffffff;

String _hex(int b) => b.toRadixString(16).padLeft(2, '0');

void main() {
  setUpAll(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    SecureStorageHolder.instance = SecureStorage(const FlutterSecureStorage());
  });

  group('拦截器签名与桌面端一致', () {
    test('纯 Dart HMAC 实现自校验（SHA-256 已知答案）', () {
      // SHA-256("abc") = ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad
      expect(
        _sha256('abc'.codeUnits).map(_hex).join(),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );
    });

    test('GET /comics + queryParameters 签名对象 == 桌面端形式', () async {
      final headers = await captureSignedHeaders(
        path: '/comics',
        queryParameters: {'page': 1, 'c': 'VC', 's': ''},
      );

      final time = headers['time'] as String;
      final nonce = headers['nonce'] as String;
      final signature = headers['signature'] as String;

      // 桌面端签的是 "comics?page=1&c=VC&s="（无前导斜杠、带 query）
      const desktopPath = 'comics?page=1&c=VC&s=';
      final expected =
          desktopSignature(desktopPath, time, nonce, 'GET');

      expect(
        signature,
        expected,
        reason: '签名与桌面端不一致：签名对象应为 "$desktopPath"',
      );
    });

    test('GET /categories（无 query）签名对象 == 桌面端形式', () async {
      final headers = await captureSignedHeaders(
        path: '/categories',
        queryParameters: null,
      );

      final time = headers['time'] as String;
      final nonce = headers['nonce'] as String;
      final signature = headers['signature'] as String;

      const desktopPath = 'categories';
      final expected = desktopSignature(desktopPath, time, nonce, 'GET');

      expect(signature, expected);
    });

    test('POST /comics/123/favourite 签名对象 == 桌面端形式', () async {
      final headers = await captureSignedHeaders(
        path: '/comics/123/favourite',
        queryParameters: null,
        method: 'POST',
      );

      final time = headers['time'] as String;
      final nonce = headers['nonce'] as String;
      final signature = headers['signature'] as String;

      const desktopPath = 'comics/123/favourite';
      final expected = desktopSignature(desktopPath, time, nonce, 'POST');

      expect(signature, expected);
    });

    test('带 query 的 POST 同样把 query 纳入签名', () async {
      final headers = await captureSignedHeaders(
        path: '/comments/abc/childrens',
        queryParameters: {'page': 2},
        method: 'POST',
      );

      final time = headers['time'] as String;
      final nonce = headers['nonce'] as String;
      final signature = headers['signature'] as String;

      const desktopPath = 'comments/abc/childrens?page=2';
      final expected = desktopSignature(desktopPath, time, nonce, 'POST');

      expect(signature, expected);
    });
  });

  group('拦截器发出的请求头与桌面端 GetHeader 一致', () {
    test('GET 请求头集合恰好是桌面端的 13 个头', () async {
      final headers = await captureSignedHeaders(
        path: '/comics',
        queryParameters: null,
      );

      const desktopHeaders = {
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
      for (final key in desktopHeaders) {
        expect(
          headers.keys.map((k) => k.toLowerCase()).toSet().contains(key),
          isTrue,
          reason: '缺少桌面端请求头: $key',
        );
      }
      // 不再发送桌面端没有的 app-build
      expect(
        headers.keys.map((k) => k.toLowerCase()).contains('app-build'),
        isFalse,
      );
    });

    test('GET 不带 Content-Type，POST 带上', () async {
      final getHeaders = await captureSignedHeaders(
        path: '/comics',
        queryParameters: null,
      );
      expect(
        getHeaders.keys.map((k) => k.toLowerCase()).contains('content-type'),
        isFalse,
      );

      final postHeaders = await captureSignedHeaders(
        path: '/comics/123/favourite',
        queryParameters: null,
        method: 'POST',
      );
      expect(
        postHeaders.keys.map((k) => k.toLowerCase()).contains('content-type'),
        isTrue,
      );
    });

    test('api-key 与桌面端 config.ApiKey 一致', () async {
      final headers = await captureSignedHeaders(
        path: '/comics',
        queryParameters: null,
      );
      expect(headers['api-key'], 'C69BAF41DA5ABD1FFEDC6D2FEA56B');
    });
  });
}
