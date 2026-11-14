import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio/io.dart' show IOHttpClientAdapter;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:picacg_flutter/core/api/api_client.dart';
import 'package:picacg_flutter/core/storage/settings_storage.dart';
import 'package:picacg_flutter/core/utils/proxy_selector.dart';

void main() {
  setUpAll(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  setUp(() {
    SettingsStorageHolder.instance = SettingsStorage(const FlutterSecureStorage());
    SettingsStorage.populateCache(const {});
  });

  tearDown(() {
    SettingsStorage.populateCache(const {});
  });

  group('ProxyConfig.proxyAuthority', () {
    test('HTTP 代理返回 host:port（不带 scheme）', () {
      expect(
        const ProxyConfig(type: ProxyType.http, host: '10.0.0.1', port: 8080)
            .proxyAuthority,
        '10.0.0.1:8080',
      );
    });

    test('SOCKS5 不走 findProxy，proxyAuthority 为 null', () {
      expect(
        const ProxyConfig(type: ProxyType.socks5, host: '127.0.0.1', port: 1080)
            .proxyAuthority,
        isNull,
      );
    });

    test('none 类型的 proxyAuthority 为 null', () {
      expect(
        const ProxyConfig(type: ProxyType.none, host: '', port: 0).proxyAuthority,
        isNull,
      );
    });

    test('host 为空时 proxyAuthority 为 null', () {
      expect(
        const ProxyConfig(type: ProxyType.http, host: '', port: 8080)
            .proxyAuthority,
        isNull,
      );
    });

    test('带用户名密码时生成认证前缀', () {
      expect(
        const ProxyConfig(
          type: ProxyType.http,
          host: 'h',
          port: 1,
          username: 'u',
          password: 'p',
        ).proxyAuthority,
        'u:p@h:1',
      );
    });
  });

  group('ProxyConfig.isUsable', () {
    test('合法配置可用', () {
      expect(
        const ProxyConfig(type: ProxyType.http, host: '1.2.3.4', port: 8080)
            .isUsable,
        isTrue,
      );
    });

    test('none 类型不可用', () {
      expect(
        const ProxyConfig(type: ProxyType.none, host: '1.2.3.4', port: 8080)
            .isUsable,
        isFalse,
      );
    });

    test('host 为空不可用', () {
      expect(
        const ProxyConfig(type: ProxyType.socks5, host: '', port: 1080).isUsable,
        isFalse,
      );
    });

    test('端口越界不可用', () {
      expect(
        const ProxyConfig(type: ProxyType.http, host: '1.2.3.4', port: 0)
            .isUsable,
        isFalse,
      );
      expect(
        const ProxyConfig(type: ProxyType.http, host: '1.2.3.4', port: 70000)
            .isUsable,
        isFalse,
      );
    });
  });

  group('ProxySelector.applyToDio — adapter 接线', () {
    test('应用 SOCKS5 代理后 adapter 带有 createHttpClient 回调', () {
      final dio = Dio();
      expect(
        (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient,
        isNull,
        reason: '初始状态不应有自定义 HttpClient 工厂',
      );

      ProxySelector.applyToDio(
        dio,
        const ProxyConfig(type: ProxyType.socks5, host: '127.0.0.1', port: 1080),
      );

      expect(
        (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient,
        isNotNull,
        reason: '代理配置必须真正接到 Dio 上（此前从未被调用）',
      );
    });

    test('应用 HTTP 代理后 adapter 带有 createHttpClient 回调', () {
      final dio = Dio();
      ProxySelector.applyToDio(
        dio,
        const ProxyConfig(type: ProxyType.http, host: '10.0.0.1', port: 8080),
      );
      expect(
        (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient,
        isNotNull,
      );
    });

    test('清除代理后 createHttpClient 被置空', () {
      final dio = Dio();
      ProxySelector.applyToDio(
        dio,
        const ProxyConfig(type: ProxyType.socks5, host: '127.0.0.1', port: 1080),
      );
      expect(
        (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient,
        isNotNull,
      );

      ProxySelector.applyToDio(dio, null);
      expect(
        (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient,
        isNull,
      );
    });

    test('none 类型与空 host 都不设置代理', () {
      final dio = Dio();
      ProxySelector.applyToDio(
        dio,
        const ProxyConfig(type: ProxyType.none, host: '1.2.3.4', port: 1),
      );
      expect(
        (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient,
        isNull,
      );

      ProxySelector.applyToDio(
        dio,
        const ProxyConfig(type: ProxyType.socks5, host: '', port: 1),
      );
      expect(
        (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient,
        isNull,
      );
    });

    test('相同配置重复应用不会重建 adapter（幂等）', () {
      final dio = Dio();
      const config =
          ProxyConfig(type: ProxyType.socks5, host: '127.0.0.1', port: 1080);

      ProxySelector.applyToDio(dio, config);
      final first = dio.httpClientAdapter;

      ProxySelector.applyToDio(dio, config);
      expect(
        identical(dio.httpClientAdapter, first),
        isTrue,
        reason: '配置未变时不应重建 adapter，否则会打断并发中的请求',
      );
    });

    test('配置变化时重建 adapter', () {
      final dio = Dio();
      ProxySelector.applyToDio(
        dio,
        const ProxyConfig(type: ProxyType.socks5, host: '127.0.0.1', port: 1080),
      );
      final first = dio.httpClientAdapter;

      ProxySelector.applyToDio(
        dio,
        const ProxyConfig(type: ProxyType.socks5, host: '127.0.0.1', port: 1081),
      );
      expect(identical(dio.httpClientAdapter, first), isFalse);
    });
  });

  group('ApiClient.resolveProxyConfig', () {
    test('未配置代理时返回 null', () {
      expect(ApiClient.resolveProxyConfig(), isNull);
    });

    test('type 为 none 时返回 null', () {
      SettingsStorage.populateCache(const {
        'proxy_config': '{"type":"none","host":"127.0.0.1","port":1080}',
      });
      expect(ApiClient.resolveProxyConfig(), isNull);
    });

    test('合法配置被正确解析', () {
      SettingsStorage.populateCache(const {
        'proxy_config': '{"type":"socks5","host":"127.0.0.1","port":1080}',
      });
      final config = ApiClient.resolveProxyConfig();
      expect(config, isNotNull);
      expect(config!.type, ProxyType.socks5);
      expect(config.host, '127.0.0.1');
      expect(config.port, 1080);
    });

    test('host 为空的配置被忽略', () {
      SettingsStorage.populateCache(const {
        'proxy_config': '{"type":"socks5","host":"","port":1080}',
      });
      expect(ApiClient.resolveProxyConfig(), isNull);
    });
  });

  group('SettingsStorage 代理配置写回同步缓存', () {
    test('setProxyConfig 立即更新 getProxyConfigSync', () async {
      final storage = SettingsStorage(const FlutterSecureStorage());
      await storage.setProxyConfig(
        const ProxyConfig(type: ProxyType.http, host: '10.0.0.1', port: 8080),
      );

      final sync = storage.getProxyConfigSync();
      expect(sync, isNotNull, reason: '写入后必须立即可被同步读取');
      expect(sync!.type, ProxyType.http);
      expect(sync.host, '10.0.0.1');
      expect(sync.port, 8080);
    });

    test('clearProxyConfig 立即清除 getProxyConfigSync', () async {
      final storage = SettingsStorage(const FlutterSecureStorage());
      await storage.setProxyConfig(
        const ProxyConfig(type: ProxyType.http, host: '10.0.0.1', port: 8080),
      );
      expect(storage.getProxyConfigSync(), isNotNull);

      await storage.clearProxyConfig();
      expect(storage.getProxyConfigSync(), isNull);
    });

    test('setApiBaseUrl 立即更新 getApiBaseUrlSync', () async {
      final storage = SettingsStorage(const FlutterSecureStorage());
      await storage.setApiBaseUrl('https://example.com');
      expect(storage.getApiBaseUrlSync(), 'https://example.com');
    });
  });

  group('HTTP 代理端到端（真实本地代理服务器）', () {
    late HttpServer proxyServer;
    late List<String> receivedRequestLines;
    late String targetHost;
    late int targetPort;

    setUp(() async {
      receivedRequestLines = <String>[];

      final target = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      target.listen((request) async {
        request.response
          ..statusCode = 200
          ..write('TARGET');
        await request.response.close();
      });
      targetHost = target.address.host;
      targetPort = target.port;

      proxyServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      proxyServer.listen((request) async {
        receivedRequestLines.add(request.uri.toString());
        request.response
          ..statusCode = 200
          ..write('VIA-PROXY');
        await request.response.close();
      });
    });

    tearDown(() async {
      await proxyServer.close(force: true);
    });

    test('请求确实经过 HTTP 代理（而非直连目标）', () async {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));
      ProxySelector.applyToDio(
        dio,
        ProxyConfig(
          type: ProxyType.http,
          host: proxyServer.address.host,
          port: proxyServer.port,
        ),
      );

      final response = await dio.get<String>('http://$targetHost:$targetPort/hello');

      expect(response.data, 'VIA-PROXY');

      expect(
        receivedRequestLines,
        isNotEmpty,
        reason: '代理服务器没有收到任何请求 —— 代理没有生效',
      );
      expect(receivedRequestLines.single, contains(targetHost));

      dio.close(force: true);
    });

    test('未配置代理时直连目标（对照实验）', () async {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));
      final response = await dio.get<String>('http://$targetHost:$targetPort/hello');

      expect(response.data, 'TARGET');
      expect(
        receivedRequestLines,
        isEmpty,
        reason: '没有代理时不应有请求到达代理服务器',
      );

      dio.close(force: true);
    });
  });

  group('SOCKS5 握手（真实本地 SOCKS5 服务器）', () {
    test('握手成功并建立隧道', () async {
      final proxy = await _FakeSocks5Server.start();
      addTearDown(proxy.stop);

      final tunnel = await ProxySelector.openSocks5Tunnel(
        proxyHost: '127.0.0.1',
        proxyPort: proxy.port,
        targetHost: 'example.com',
        targetPort: 443,
      );
      addTearDown(tunnel.destroy);

      expect(proxy.negotiatedVersion, 0x05);
      expect(proxy.negotiatedMethod, 0x00, reason: '应选择"无需认证"');
      expect(proxy.connectTargetHost, 'example.com');
      expect(proxy.connectTargetPort, 443);
    });

    test('代理拒绝连接时抛出异常', () async {
      final proxy = await _FakeSocks5Server.start(replyCode: 0x05);
      addTearDown(proxy.stop);

      await expectLater(
        ProxySelector.openSocks5Tunnel(
          proxyHost: '127.0.0.1',
          proxyPort: proxy.port,
          targetHost: 'example.com',
          targetPort: 443,
        ),
        throwsA(isA<SocketException>()),
      );
    });

    test('用户名/密码认证子协商（RFC 1929）', () async {
      final proxy = await _FakeSocks5Server.start(requireAuth: true);
      addTearDown(proxy.stop);

      final tunnel = await ProxySelector.openSocks5Tunnel(
        proxyHost: '127.0.0.1',
        proxyPort: proxy.port,
        targetHost: 'example.com',
        targetPort: 443,
        username: 'user',
        password: 'pass',
      );
      addTearDown(tunnel.destroy);

      expect(proxy.negotiatedMethod, 0x02);
      expect(proxy.authUsername, 'user');
      expect(proxy.authPassword, 'pass');
    });
  });

  group('SOCKS5 端到端：Dio 真正走 SOCKS5 代理', () {
    // 这一组是本批的核心回归测试。
    //
    // 之前的测试只验证"握手函数本身"能跑通，却没有验证
    // **Dio 经由 SOCKS5 发起真实请求**。于是下面这个缺陷
    // 一直没能被发现：
    //
    //   dart:io 的 `Socket` 是**单订阅**流。握手阶段 `_ByteReader`
    //   订阅了 socket，握手结束后原实现调用 `reader.detach()`
    //   **取消**了该订阅，随后把这个 socket 交给 HttpClient；
    //   HttpClient 必然要 `socket.listen(...)`
    //   （dart-sdk `lib/_http/http_parser.dart:344`），
    //   于是抛 `StateError: Stream has already been listened to`。
    //
    // 也就是说：SOCKS5 代理在**任何真实请求**下都是坏的，
    // 而单元测试全绿。

    late _FakeSocks5Server proxy;
    late HttpServer target;
    late List<String> targetRequests;

    setUp(() async {
      targetRequests = <String>[];

      target = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      target.listen((request) async {
        targetRequests.add(request.uri.path);
        request.response
          ..statusCode = 200
          ..write('VIA-SOCKS5');
        await request.response.close();
      });

      proxy = await _FakeSocks5Server.start(relayToTarget: true);
    });

    tearDown(() async {
      await proxy.stop();
      await target.close(force: true);
    });

    test('Dio 经 SOCKS5 代理请求成功（不抛 StateError）', () async {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));
      addTearDown(() => dio.close(force: true));

      ProxySelector.applyToDio(
        dio,
        ProxyConfig(
          type: ProxyType.socks5,
          host: '127.0.0.1',
          port: proxy.port,
        ),
      );

      final response = await dio.get<String>(
        'http://${target.address.host}:${target.port}/hello',
      );

      expect(
        response.data,
        'VIA-SOCKS5',
        reason: '响应必须来自目标站点（经代理转发）',
      );
      expect(
        targetRequests,
        contains('/hello'),
        reason: '目标站点必须收到请求 —— 说明 SOCKS5 隧道确实通了',
      );
      expect(
        proxy.negotiatedMethod,
        0x00,
        reason: '代理必须完成过 SOCKS5 方法协商',
      );
    });

    test('SOCKS5 代理未配置时直连目标（对照实验）', () async {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));
      addTearDown(() => dio.close(force: true));

      final response = await dio.get<String>(
        'http://${target.address.host}:${target.port}/hello',
      );

      expect(response.data, 'VIA-SOCKS5');
      expect(proxy.connectTargetHost, isNull,
          reason: '没配置代理时不应与 SOCKS5 服务器握手');
    });
  });
}

/// 最小 SOCKS5 服务器（RFC 1928 / RFC 1929），用于验证握手实现。
///
/// 必须用裸 `ServerSocket`：`HttpServer` 只会解析 HTTP 报文，
/// 无法处理 SOCKS5 的二进制握手。
class _FakeSocks5Server {
  _FakeSocks5Server._(this._server);

  static Future<_FakeSocks5Server> start({
    int replyCode = 0x00,
    bool requireAuth = false,
    bool relayToTarget = false,
  }) async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final instance = _FakeSocks5Server._(server);
    instance._replyCode = replyCode;
    instance._requireAuth = requireAuth;
    instance._relayToTarget = relayToTarget;
    instance._sub = server.listen(instance._handle);
    return instance;
  }

  final ServerSocket _server;
  int _replyCode = 0x00;
  bool _requireAuth = false;
  bool _relayToTarget = false;
  StreamSubscription<Socket>? _sub;

  int negotiatedVersion = -1;
  int negotiatedMethod = -1;
  String? authUsername;
  String? authPassword;
  String? connectTargetHost;
  int connectTargetPort = -1;

  int get port => _server.port;

  Future<void> _handle(Socket socket) async {
    try {
      final reader = _SocketReader(socket);

      // --- 1/2. 方法协商 ---
      final greeting = await reader.readExactly(2);
      negotiatedVersion = greeting[0];
      final methodCount = greeting[1];
      final methods = await reader.readExactly(methodCount);

      final chosen = _requireAuth
          ? (methods.contains(0x02) ? 0x02 : 0xFF)
          : (methods.contains(0x00) ? 0x00 : 0xFF);
      negotiatedMethod = chosen;
      socket.add([0x05, chosen]);
      await socket.flush();

      if (chosen == 0xFF) {
        socket.destroy();
        return;
      }

      // --- 3. RFC 1929 用户名/密码子协商 ---
      if (chosen == 0x02) {
        final ver = await reader.readExactly(1);
        if (ver[0] != 0x01) {
          socket.destroy();
          return;
        }
        final userLen = (await reader.readExactly(1))[0];
        authUsername = utf8.decode(await reader.readExactly(userLen));
        final passLen = (await reader.readExactly(1))[0];
        authPassword = utf8.decode(await reader.readExactly(passLen));
        socket.add([0x01, 0x00]);
        await socket.flush();
      }

      // --- 4. CONNECT 请求 ---
      final header = await reader.readExactly(4);
      if (header[0] != 0x05 || header[1] != 0x01) {
        socket.destroy();
        return;
      }
      final atyp = header[3];
      if (atyp == 0x03) {
        final len = (await reader.readExactly(1))[0];
        connectTargetHost = utf8.decode(await reader.readExactly(len));
      } else if (atyp == 0x01) {
        connectTargetHost = (await reader.readExactly(4)).join('.');
      } else if (atyp == 0x04) {
        final raw = await reader.readExactly(16);
        connectTargetHost = raw
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join(':');
      } else {
        socket.destroy();
        return;
      }
      final portBytes = await reader.readExactly(2);
      connectTargetPort = (portBytes[0] << 8) | portBytes[1];

      // --- 5. 应答 ---
      socket.add([0x05, _replyCode, 0x00, 0x01, 0, 0, 0, 0, 0, 0]);
      await socket.flush();

      if (!_relayToTarget) {
        return;
      }

      // --- 6. 真正把隧道接到目标站点（端到端测试需要） ---
      //
      // ⚠️ 不能在这里对 `socket` 再 `listen` 一次：dart:io 的 `Socket` 是
      // **单订阅**流，`_SocketReader` 已经订阅过一次，再订阅会抛
      // `StateError: Stream has already been listened to`。
      // 因此必须让**同一个** reader 在握手后切换到"透传"模式。
      final upstream = await Socket.connect(
        connectTargetHost!,
        connectTargetPort,
      );
      reader.startPassthrough((chunk) => upstream.add(chunk));

      final upSub = upstream.listen(
        (chunk) => socket.add(chunk),
        onDone: () => socket.destroy(),
        onError: (_) => socket.destroy(),
      );
      // 等待任一方向结束（不主动 cancel，否则会把转发打断）。
      await upSub.asFuture<void>().catchError((_) {});
    } catch (_) {
      // 客户端提前断开属于预期情况。
    }
  }

  Future<void> stop() async {
    await _sub?.cancel();
    await _server.close();
  }
}

/// 裸 socket 的精确字节读取器（与被测实现的 `_ByteReader` 同思路）。
class _SocketReader {
  _SocketReader(this._socket) {
    _subscription = _socket.listen(
      (chunk) {
        if (_passthrough) {
          _onPassthrough?.call(chunk);
        } else {
          _buffer.addAll(chunk);
        }
        _signal();
      },
      onError: (Object error, StackTrace _) {
        _error = error;
        _signal();
      },
      onDone: () {
        _done = true;
        _signal();
      },
    );
  }

  final Socket _socket;
  final List<int> _buffer = <int>[];
  late final StreamSubscription<Uint8List> _subscription;
  Completer<void>? _waiter;
  Object? _error;
  bool _done = false;
  bool _passthrough = false;
  void Function(List<int>)? _onPassthrough;

  /// 握手完成后切换到透传模式：收到的数据直接交给 [sink]。
  ///
  /// dart:io 的 `Socket` 只能订阅一次，因此透传必须复用**同一个**订阅，
  /// 不能再 `listen` 一遍。
  void startPassthrough(void Function(List<int>) sink) {
    _passthrough = true;
    _onPassthrough = sink;
    if (_buffer.isEmpty) return;
    final leftover = List<int>.from(_buffer);
    _buffer.clear();
    sink(leftover);
  }

  void _signal() {
    final waiter = _waiter;
    if (waiter != null && !waiter.isCompleted) {
      _waiter = null;
      waiter.complete();
    }
  }

  Future<List<int>> readExactly(int count) async {
    while (_buffer.length < count) {
      if (_error != null) throw _error!;
      if (_done) {
        throw SocketException(
            'SOCKS5 连接在读取 $count 字节前被关闭（已收到 ${_buffer.length} 字节）');
      }
      final waiter = Completer<void>();
      _waiter = waiter;
      await waiter.future;
    }
    final out = _buffer.sublist(0, count);
    _buffer.removeRange(0, count);
    return out;
  }

  /// 取消监听（测试收尾用）。
  Future<void> cancel() async {
    await _subscription.cancel();
  }
}
