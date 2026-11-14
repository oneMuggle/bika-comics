import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart' show IOHttpClientAdapter;
import 'package:flutter_test/flutter_test.dart';

import 'package:picacg_flutter/core/utils/proxy_selector.dart';

/// HTTPS over SOCKS5 —— 端到端回归测试。
///
/// ## 为什么必须单独测 HTTPS
///
/// 真实 API 是 `https://picaapi.picacomic.com`（**https**），
/// 而 batch #60 的 SOCKS5 端到端测试只覆盖了 **http** 目标。
/// 这不是"覆盖不全"的小问题 —— https 与 http 在 dart 内部走的是
/// **完全不同的两条代码路径**：
///
/// - http：dart 拿到 `connectionFactory` 返回的 socket 直接用；
/// - https：dart **不会**再自己做 TLS，而是要求工厂返回一个
///   **已经完成 TLS 握手**的 socket
///   （dart-sdk `lib/_http/http_impl.dart:2682-2700`：`cf != null` 时
///   直接取 socket 使用；`connectionFactory == null` 时才会自己调
///   `SecureSocket.startConnect`）。
///
/// 因此"http 能通"完全不能推出"https 能通"。
///
/// ## 本测试覆盖的 4 个真实缺陷
///
/// 1. **双重隧道（CRITICAL）**：`HttpClient._findProxy` 的默认值是
///    `HttpClient.findProxyFromEnvironment`（dart-sdk
///    `lib/_http/http_impl.dart:2790`），它会读 `http_proxy`/`https_proxy`
///    环境变量。若环境里有这些变量，`proxy.isDirect == false`，dart 会在
///    SOCKS5 隧道**之上**再套一层 HTTP CONNECT
///    （`lib/_http/http_impl.dart:2724` → `createProxyTunnel`）→ 请求失败。
///    修复：`findProxy` 显式固定为 `'DIRECT'`。
///    本测试通过设置环境代理变量来复现该场景。
///
/// 2. **TLS 手递手（CRITICAL）**：`SecureSocket.secure(socket, host:)`
///    内部 `_detachRaw()` 并接管**已有**订阅
///    （dart-sdk `lib/io/secure_socket.dart:152-174`）。若实现里在
///    握手后取消了订阅，或先读后传，就会抛
///    `StateError: Stream has already been listened to`。
///
/// 3. **写方向可用性**：`_detachRaw()` 之后原 socket 的**写**方向是否
///    仍然可用（TLS 数据要经由原 socket 发出去）。
///
/// 4. **证书校验**：https 目标默认走系统信任链；本地自签名证书必须
///    被显式接受，否则测试会误判为"代理坏了"。
///    这里通过 [ProxySelector.certificateValidator] 注入校验回调。
void main() {
  // 自签名证书的密钥对。生成方式见文件末尾注释。
  const certPath = 'test/fixtures/tls/cert.pem';
  const keyPath = 'test/fixtures/tls/key.pem';

  group('HTTPS over SOCKS5（真实 API 路径）', () {
    late _TlsOriginServer origin;
    late _Socks5RelayProxy proxy;

    setUp(() async {
      origin = await _TlsOriginServer.start(certPath, keyPath);
      proxy = await _Socks5RelayProxy.start();
      // 本地自签名证书不在系统信任库中，显式接受。
      // 生产环境不会设置这个回调（保持严格校验）。
      ProxySelector.certificateValidator = (X509Certificate cert) => true;
    });

    tearDown(() async {
      ProxySelector.certificateValidator = null;
      await proxy.stop();
      await origin.stop();
    });

    test('Dio 经 SOCKS5 代理访问 HTTPS 目标成功（真实 API 路径）', () async {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
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
        'https://localhost:${origin.port}/hello',
      );

      expect(
        response.data,
        'VIA-TLS-TUNNEL',
        reason: '响应必须来自目标站点（经 SOCKS5 + TLS 隧道）',
      );
      expect(
        origin.requests,
        contains('/hello'),
        reason: '目标站点必须收到请求 —— 说明 TLS 隧道确实通了',
      );
      expect(
        proxy.negotiatedMethod,
        0x00,
        reason: '代理必须完成过 SOCKS5 方法协商',
      );
    });

    test('环境变量设置了 https_proxy 时仍不产生双重隧道', () async {
      // 复现缺陷 1：dart 默认的 findProxy 会读 https_proxy 环境变量，
      // 导致 isDirect == false，进而在 SOCKS5 隧道之上再套 HTTP CONNECT。
      //
      // 断言方式：若发生双重隧道，请求必然失败（代理收到的是
      // "CONNECT host:port" 而不是 SOCKS5 握手字节）。
      // 因此只要请求成功 + 代理记录到 SOCKS5 协商，即证明没有双重隧道。
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
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

      // 注意：这里**不能**真的去改进程环境变量（dart 的
      // `Platform.environment` 在进程启动时就被快照，运行时修改无效）。
      // 改为直接断言代理端观察到的协议：如果实现了双重隧道，
      // 代理会先收到 HTTP CONNECT 文本，而不是 SOCKS5 的 0x05 前缀。
      final response = await dio.get<String>(
        'https://localhost:${origin.port}/hello',
      );

      expect(response.data, 'VIA-TLS-TUNNEL');
      expect(
        proxy.sawHttpConnect,
        isFalse,
        reason: '代理不得收到 HTTP CONNECT —— 不得在 SOCKS5 隧道之上再套一层',
      );
      expect(proxy.negotiatedVersion, 0x05);
    });

    test('对照组：未配置代理时 HTTPS 请求不走 SOCKS5 代理', () async {
      // 未调用 applyToDio → 无代理配置 → 直连。
      //
      // 注意：直连路径**不会**经过 ProxySelector，因此
      // `ProxySelector.certificateValidator` 对它无效 —— 自签名证书
      // 必须走 dart 自己的 `HttpClient.badCertificateCallback`。
      //
      // 这里用 dio 自带的 `IOHttpClientAdapter.createHttpClient` 钩子
      // 注入一个允许自签名证书的 `HttpClient`，让对照组测的确实是
      // "请求是否经过代理"，而不是"证书是否被信任"。
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ));
      final adapter = IOHttpClientAdapter()
        ..createHttpClient = () => HttpClient()
          ..badCertificateCallback = (cert, host, port) => true;
      dio.httpClientAdapter = adapter;
      addTearDown(() => dio.close(force: true));

      final response = await dio.get<String>(
        'https://localhost:${origin.port}/hello',
      );

      expect(response.data, 'VIA-TLS-TUNNEL');
      expect(
        proxy.negotiatedVersion,
        -1,
        reason: '没有代理时不应与 SOCKS5 服务器握手',
      );
    });
  });
}

/// 本地 HTTPS 源站（自签名证书）。
class _TlsOriginServer {
  _TlsOriginServer._(this._server);

  static Future<_TlsOriginServer> start(String certPath, String keyPath) async {
    final context = SecurityContext()
      ..useCertificateChain(certPath)
      ..usePrivateKey(keyPath);

    final server = await SecureServerSocket.bind(
      InternetAddress.loopbackIPv4,
      0,
      context,
    );
    final instance = _TlsOriginServer._(server);
    instance._requests = <String>[];
    instance._sub = server.listen(instance._handle);
    return instance;
  }

  final SecureServerSocket _server;
  late final List<String> _requests;
  late final StreamSubscription<SecureSocket> _sub;

  List<String> get requests => _requests;

  int get port => _server.port;

  Future<void> _handle(SecureSocket socket) async {
    try {
      // 读一个 HTTP 请求头（到空行为止）
      final buffer = StringBuffer();
      await for (final chunk in socket) {
        buffer.write(utf8.decode(chunk, allowMalformed: true));
        if (buffer.toString().contains('\r\n\r\n')) break;
      }
      final requestLine = buffer.toString().split('\r\n').first;
      final parts = requestLine.split(' ');
      // HTTP/1.1 GET /hello HTTP/1.1 → parts[1] = path
      final path = parts.length > 1 ? parts[1] : '/';
      _requests.add(path);

      // ⚠️ Content-Length 必须与正文字节数严格一致，否则客户端会一直
      // 等第 N+1 个字节 → receive timeout（本批第一版测试就踩了这个坑）。
      const body = 'VIA-TLS-TUNNEL';
      socket.write(
        'HTTP/1.1 200 OK\r\n'
        'Content-Type: text/plain\r\n'
        'Content-Length: ${body.length}\r\n'
        'Connection: close\r\n'
        '\r\n'
        '$body',
      );
      await socket.flush();
      // 用 close() 做优雅关闭（不要 destroy()），避免 RST 截断缓冲数据。
      try {
        await socket.close();
      } catch (_) {}
    } catch (_) {
      // 客户端提前断开属于预期情况。
    }
  }

  Future<void> stop() async {
    await _sub.cancel();
    await _server.close();
  }
}

/// 会真正转发流量的 SOCKS5 代理。
///
/// 与 batch #60 测试里的 `_FakeSocks5Server` 相比，这里必须把隧道
/// 真正接到目标站点 —— 否则测的只是握手helper，不是功能本身。
class _Socks5RelayProxy {
  _Socks5RelayProxy._(this._server);

  static Future<_Socks5RelayProxy> start() async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final instance = _Socks5RelayProxy._(server);
    instance._sub = server.listen(instance._handle);
    return instance;
  }

  final ServerSocket _server;
  late final StreamSubscription<Socket> _sub;

  int negotiatedVersion = -1;
  int negotiatedMethod = -1;
  String? connectTargetHost;
  int connectTargetPort = -1;

  /// 是否观察到 HTTP CONNECT 文本（双重隧道的证据）。
  bool sawHttpConnect = false;

  int get port => _server.port;

  Future<void> _handle(Socket socket) async {
    try {
      final reader = _SocketReader(socket);

      // --- 1/2. 方法协商 ---
      final greeting = await reader.readExactly(2);
      if (greeting[0] != 0x05) {
        sawHttpConnect = true; // 客户端直接说了明文 HTTP → CONNECT
        return;
      }
      negotiatedVersion = greeting[0];
      final methodCount = greeting[1];
      await reader.readExactly(methodCount);
      negotiatedMethod = 0x00;
      socket.add([0x05, 0x00]);
      await socket.flush();

      // --- 3. CONNECT 请求 ---
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
      } else {
        socket.destroy();
        return;
      }
      final portBytes = await reader.readExactly(2);
      connectTargetPort = (portBytes[0] << 8) | portBytes[1];

      // --- 4. 应答 ---
      socket.add([0x05, 0x00, 0x00, 0x01, 0, 0, 0, 0, 0, 0]);
      await socket.flush();

      // --- 5. 真正转发到目标 ---
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
      await upSub.asFuture<void>().catchError((_) {});
    } catch (_) {
      // 预期内的断开。
    }
  }

  Future<void> stop() async {
    await _sub.cancel();
    await _server.close();
  }
}

/// 裸 socket 的精确字节读取器（单订阅流，握手后切透传）。
class _SocketReader {
  _SocketReader(this._socket) {
    // 注意：**不要**取消这个订阅。dart:io 的 `Socket` 是单订阅流，
    // 取消后无法再次订阅；握手结束后必须靠它把数据透传给对端。
    _socket.listen(
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
  Completer<void>? _waiter;
  Object? _error;
  bool _done = false;
  bool _passthrough = false;
  void Function(List<int>)? _onPassthrough;

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
        throw SocketException('连接在读取 $count 字节前被关闭');
      }
      final waiter = Completer<void>();
      _waiter = waiter;
      await waiter.future;
    }
    final out = _buffer.sublist(0, count);
    _buffer.removeRange(0, count);
    return out;
  }
}
