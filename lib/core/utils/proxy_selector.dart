import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio/io.dart' show IOHttpClientAdapter;

/// 代理配置模型
enum ProxyType { none, socks5, http }

class ProxyConfig {
  final ProxyType type;
  final String host;
  final int port;
  final String? username;
  final String? password;

  const ProxyConfig({
    required this.type,
    required this.host,
    required this.port,
    this.username,
    this.password,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'host': host,
        'port': port,
        'username': username,
        'password': password,
      };

  factory ProxyConfig.fromJson(Map<String, dynamic> json) => ProxyConfig(
        type: ProxyType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => ProxyType.none,
        ),
        host: json['host'] ?? '',
        port: json['port'] ?? 0,
        username: json['username'],
        password: json['password'],
      );

  /// `dart:io` `findProxy` 期望的 `host:port` 形式（可带 `user:pass@` 前缀）。
  ///
  /// Dart 的 `_ProxyConfiguration` 解析器只接受 `PROXY host:port` 与
  /// `DIRECT` 两种指令（dart-sdk `lib/_http/http_impl.dart:3688`），
  /// **不解析 scheme**，因此这里不能返回 `http://host:port`。
  ///
  /// 仅 HTTP 代理适用；SOCKS5 不走 `findProxy`（见 [ProxySelector]）。
  String? get proxyAuthority {
    if (type != ProxyType.http) return null;
    if (host.isEmpty) return null;
    final auth = _authPrefix;
    return '$auth$host:$port';
  }

  String get _authPrefix =>
      (username != null && password != null && username!.isNotEmpty)
          ? '$username:$password@'
          : '';

  /// 代理配置是否足以发起连接。
  bool get isUsable =>
      type != ProxyType.none && host.isNotEmpty && port > 0 && port <= 65535;

  /// 配置指纹，用于检测配置是否变化（避免每次请求都重建 adapter）。
  String get signature => type == ProxyType.none
      ? 'none'
      : '${type.name}|$host|$port|${username ?? ''}|${password ?? ''}';
}

/// 代理选择器工具类
class ProxySelector {
  ProxySelector._();

  /// 可选的证书校验回调。
  ///
  /// 默认 `null` → 使用系统默认信任链校验（严格，生产正确行为）。
  ///
  /// 暴露该入口有两个正当用途：
  /// 1. **企业 MITM 代理**：部分企业代理会用自有 CA 重新签发证书。
  ///    此时正确做法是把企业 CA 加入信任库，而不是放宽校验。
  /// 2. **自动化测试**：本地自签名 HTTPS 测试服务器无法被系统信任库接受。
  ///
  /// ⚠️ 传入恒返回 `true` 的回调等于关闭证书校验，
  /// 仅应在受控环境（测试 / 明确信任的企业网络）使用。
  ///
  /// 对应 dart API（两者签名不同，此处已统一）：
  /// - SOCKS5 路径 → `SecureSocket.secure(..., onBadCertificate: ...)`
  ///   签名 `bool Function(X509Certificate)`
  /// - HTTP 代理路径 → `HttpClient.badCertificateCallback`
  ///   签名 `bool Function(X509Certificate, String, int)`
  static bool Function(X509Certificate)? certificateValidator;

  /// 记录"当前 Dio 上已应用的代理配置"的 key。
  static const String _appliedKey = '__proxy_applied_signature';

  /// 把代理配置应用到 Dio。
  ///
  /// 第五十九批：此前本方法**从未被调用**——设置页能保存代理配置，
  /// `ApiClient` 里也留了「配置代理」注释，但实际没有任何代码把它接到
  /// Dio 上，代理开关对网络请求完全无效（真实 P2 缺口）。
  ///
  /// 桌面端对应实现：
  /// - `src/server/server.py:161-180` — `UpdateProxy2()` 按
  ///   `Setting.IsHttpProxy` 在 http / socks5 / 系统代理之间选择，
  ///   并把代理挂到全局 `httpx.Client(proxy=proxy)` 上；
  /// - `src/server/req.py:49-67` — 按域名分流到 `ProxyApiDomain` 等镜像。
  ///
  /// 移动端的做法与桌面端不同：桌面端是"分流域名"（把 API 域名替换成
  /// 代理域名），移动端则是标准 HTTP/SOCKS5 代理。两种都能让请求经由代理
  /// 转发，因此这里实现标准代理。
  ///
  /// 实现方式分两种：
  /// - **HTTP 代理**：`HttpClient.findProxy` 返回 `PROXY host:port`。
  ///   Dart 会自动对 https 目标使用 CONNECT 隧道。
  /// - **SOCKS5 代理**：`dart:io` 没有 SOCKS 支持（`_ProxyConfiguration`
  ///   只解析 `PROXY` 与 `DIRECT`），必须用
  ///   `HttpClient.connectionFactory` 接管 socket 建连，见 [_applySocks5]。
  ///
  /// ⚠️ `findProxy` 的入参 `uri` 是**目标地址**（dart-sdk
  /// `lib/_http/http_impl.dart:3011` 调用 `findProxy(uri)`），返回值才是
  /// **代理地址**。写成 `'PROXY $uri'` 会让请求指向目标站点自身，
  /// 代理完全失效。
  static void applyToDio(Dio dio, ProxyConfig? config) {
    final effective = (config != null && config.isUsable) ? config : null;
    final signature = effective?.signature ?? 'none';

    // 幂等：配置没变就不动 adapter。
    //
    // `ApiClient.instance` 每次被访问都会调用本方法，而 `_dio` 是全局单例。
    // 若无脑重建 adapter，不仅白白浪费，还会 `close` 掉正在使用的
    // `HttpClient`，把**并发中的请求**一起打断。
    if (dio.options.extra[_appliedKey] == signature) return;

    if (effective == null) {
      _clearProxy(dio);
    } else {
      switch (effective.type) {
        case ProxyType.http:
          _applyHttp(dio, effective);
          break;
        case ProxyType.socks5:
          _applySocks5(dio, effective);
          break;
        case ProxyType.none:
          _clearProxy(dio);
          break;
      }
    }
    dio.options.extra[_appliedKey] = signature;
  }

  /// HTTP 代理：通过 `HttpClient.findProxy` 返回 `PROXY host:port`。
  ///
  /// dart 对 https 目标会自动使用 CONNECT 隧道
  /// （dart-sdk `lib/_http/http_impl.dart:2724` → `createProxyTunnel`），
  /// 因此这里只需给出代理地址，不需要自己实现隧道。
  static void _applyHttp(Dio dio, ProxyConfig config) {
    final authority = config.proxyAuthority;
    if (authority == null) {
      _clearProxy(dio);
      return;
    }

    _replaceAdapter(dio, (client) {
      client.findProxy = (Uri target) => 'PROXY $authority';

      // 仅在显式配置了校验回调时才覆盖；默认保持 dart 的严格校验。
      //
      // 注意 `HttpClient.badCertificateCallback` 的签名是
      // `bool Function(X509Certificate, String, int)`（带 host/port），
      // 而 `SecureSocket.secure` 的 `onBadCertificate` 是
      // `bool Function(X509Certificate)`。这里统一成前者。
      final validator = ProxySelector.certificateValidator;
      if (validator != null) {
        client.badCertificateCallback = (cert, host, port) => validator(cert);
      }
    });
  }

  /// SOCKS5 代理：通过 `HttpClient.connectionFactory` 接管 socket 建连。
  ///
  /// `dart:io` 的 `HttpClient` 原生不支持 SOCKS5，只能自己完成
  /// SOCKS5 握手（method negotiation → CONNECT → 目标地址）。
  ///
  /// `connectionFactory` 的签名是
  /// `(Uri url, String? proxyHost, int? proxyPort) -> Future<ConnectionTask<Socket>>`，
  /// 返回的 socket 即到目标站点的隧道。
  ///
  /// 注意：**https 目标的 TLS 必须由本方法自己完成**。
  /// 当 `connectionFactory` 非空时，dart 不会再对 socket 做 TLS
  /// （dart-sdk `lib/_http/http_impl.dart:2682`：`cf != null` 分支直接
  /// 拿 socket 用），因此 https 必须返回 `SecureSocket`。
  static void _applySocks5(Dio dio, ProxyConfig config) {
    final proxyHost = config.host;
    final proxyPort = config.port;
    final username = config.username;
    final password = config.password;

    _replaceAdapter(dio, (client) {
      // ⚠️ 必须显式把 findProxy 固定为 DIRECT，不能依赖 dart 的默认值。
      //
      // dart 的 `HttpClient._findProxy` 默认是
      // `HttpClient.findProxyFromEnvironment`（dart-sdk
      // `lib/_http/http_impl.dart:2790`），它会读取 `http_proxy` /
      // `https_proxy` 环境变量。若设备/运行环境里恰好设置了这些变量，
      // `findProxy(uri)` 返回的就不再是 DIRECT，于是
      // `proxy.isDirect == false`：
      //
      //   1. `connectionFactory` 会被以 `(uri, host, port)` 调用
      //      （`lib/_http/http_impl.dart:2688`），语义变成"连到该代理"，
      //      而我们返回的其实是**已经穿过 SOCKS5 的隧道**；
      //   2. 对 https 目标，dart 还会额外调用 `createProxyTunnel(...)`
      //      （`lib/_http/http_impl.dart:2724`），在 SOCKS5 隧道**之上**
      //      再套一层 HTTP CONNECT —— 双重代理，请求必然失败。
      //
      // 固定为 DIRECT 后：`proxy.isDirect == true`，
      // dart 走 `cf(uri, null, null)` 分支，既不会二次建隧道，
      // 也不会对 https 再套 CONNECT；隧道完全由下面的 SOCKS5 握手负责。
      client.findProxy = (Uri target) => 'DIRECT';

      client.connectionFactory = (target, _, __) async {
        final tunnel = await openSocks5Tunnel(
          proxyHost: proxyHost,
          proxyPort: proxyPort,
          targetHost: target.host,
          targetPort: target.hasPort ? target.port : 443,
          username: username,
          password: password,
        );
        if (target.scheme == 'https') {
          // `SecureSocket.secure` 内部会调用 `socket._detachRaw()`，
          // 并把**现有的** stream subscription 一并接管
          // （dart-sdk `lib/io/secure_socket.dart:152-174`），
          // 因此握手用的监听不会被取消，HttpClient 之后可以正常订阅。
          final secure = await tunnel.upgradeToTls(target.host);
          return ConnectionTask.fromSocket<Socket>(
            Future<Socket>.value(secure),
            () => secure.destroy(),
          );
        }
        // http 目标：握手期间建立的监听必须继续存活（dart:io 的 `Socket`
        // 是**单订阅**流，取消后 HttpClient 再订阅会抛
        // `StateError: Stream has already been listened to`），
        // 因此把监听留在 `_TunnelSocket` 内部，由它把数据喂给 HttpClient。
        return ConnectionTask.fromSocket<Socket>(
          Future<Socket>.value(tunnel.asSocket()),
          () => tunnel.destroy(),
        );
      };
    });
  }

  /// 完成一次 SOCKS5 CONNECT 握手，返回到目标站点的隧道。
  ///
  /// 协议（RFC 1928 / RFC 1929）：
  /// 1. 客户端 → `05 NM 00...`（NM = 支持的方法个数）
  /// 2. 服务端 → `05 M`（M = 选中的认证方法）
  /// 3. 若 M = 02（用户名/密码）→ 子协商 RFC 1929：
  ///    `01 ULEN USER PLEN PASS` → 应答 `01 00`（成功）
  /// 4. 客户端 → `05 01 00 03 LEN HOST PORT`（01 = CONNECT）
  /// 5. 服务端 → `05 REP 00 ATYP BND.ADDR BND.PORT`（REP = 00 成功）
  ///
  /// ⚠️ 关键：返回的 [Socks5Tunnel] **不会取消**握手用的 stream 订阅。
  /// dart:io 的 `Socket` 是单订阅流（内部是
  /// `StreamController<Uint8List>(sync: true)`，
  /// dart-sdk `lib/_internal/vm/bin/socket_patch.dart:2678`），
  /// 一旦取消订阅，后续再 `listen` 会抛
  /// `StateError: Stream has already been listened to`。
  /// 而 `HttpClient` 拿到隧道后必然会自己订阅这个 socket
  /// （dart-sdk `lib/_http/http_parser.dart:344`：`stream.listen(...)`）。
  ///
  /// 因此：
  /// - https 目标 → 交给 `SecureSocket.secure`，它内部会 `_detachRaw()`
  ///   并**接管**现有订阅（dart-sdk `lib/io/secure_socket.dart:152-174`）；
  /// - http 目标 → 用 [_TunnelSocket] 把同一个订阅的数据转发给 HttpClient。
  static Future<Socks5Tunnel> openSocks5Tunnel({
    required String proxyHost,
    required int proxyPort,
    required String targetHost,
    required int targetPort,
    String? username,
    String? password,
  }) async {
    final socket = await Socket.connect(proxyHost, proxyPort);
    final reader = _ByteReader(socket);
    try {
      // --- 1/2. 方法协商 ---
      final methods = <int>[0x00];
      if (username != null && password != null && username.isNotEmpty) {
        methods.add(0x02);
      }
      socket.add([0x05, methods.length, ...methods]);
      await socket.flush();

      final greeting = await reader.readExactly(2);
      if (greeting[0] != 0x05) {
        throw SocketException('SOCKS5 代理返回了非法版本: ${greeting[0]}');
      }
      final method = greeting[1];
      if (method == 0xFF) {
        throw const SocketException('SOCKS5 代理拒绝了所有认证方式');
      }
      if (method == 0x02) {
        if (username == null || password == null) {
          throw const SocketException('SOCKS5 代理要求用户名/密码认证，但未配置');
        }
        // --- 3. RFC 1929 用户名/密码子协商 ---
        final userBytes = utf8.encode(username);
        final passBytes = utf8.encode(password);
        socket.add([
          0x01,
          userBytes.length,
          ...userBytes,
          passBytes.length,
          ...passBytes,
        ]);
        await socket.flush();
        final authReply = await reader.readExactly(2);
        if (authReply[1] != 0x00) {
          throw const SocketException('SOCKS5 代理认证失败');
        }
      } else if (method != 0x00) {
        throw SocketException('SOCKS5 代理选择了不支持的认证方式: $method');
      }

      // --- 4. CONNECT 请求 ---
      final hostBytes = utf8.encode(targetHost);
      socket.add([
        0x05, // version
        0x01, // CONNECT
        0x00, // reserved
        0x03, // ATYP = domain name
        hostBytes.length,
        ...hostBytes,
        (targetPort >> 8) & 0xFF,
        targetPort & 0xFF,
      ]);
      await socket.flush();

      // --- 5. 应答 ---
      final reply = await reader.readExactly(4);
      if (reply[0] != 0x05) {
        throw SocketException('SOCKS5 代理返回了非法版本: ${reply[0]}');
      }
      if (reply[1] != 0x00) {
        throw SocketException(
            'SOCKS5 代理拒绝连接目标 $targetHost:$targetPort (REP=${reply[1]}');
      }
      // 跳过 BND.ADDR / BND.PORT
      final atyp = reply[3];
      switch (atyp) {
        case 0x01:
          await reader.readExactly(4);
          break;
        case 0x04:
          await reader.readExactly(16);
          break;
        case 0x03:
          final len = (await reader.readExactly(1))[0];
          await reader.readExactly(len);
          break;
        default:
          throw SocketException('SOCKS5 代理返回了未知地址类型: $atyp');
      }
      await reader.readExactly(2);

      // 握手完成。注意：**不取消** reader 的订阅 —— 见本方法的文档说明。
      return Socks5Tunnel._(socket, reader);
    } catch (_) {
      reader.cancel();
      socket.destroy();
      rethrow;
    }
  }
  /// 用一个新的 `HttpClient` 替换 Dio 的 adapter。
  ///
  /// ⚠️ 关键点：Dio 的 `IOHttpClientAdapter` 会把首次创建的 `HttpClient`
  /// **缓存**在 `_cachedHttpClient` 字段里（dio-5.10.0
  /// `lib/src/adapters/io_adapter.dart:241`），之后 `createHttpClient`
  /// 回调再也不会被调用。而 `dio.httpClientAdapter = adapter` 只是给
  /// 一个普通的 `late` 字段赋值（`dio_mixin.dart:40`），**没有任何副作用**，
  /// 因此"重新赋值同一个 adapter"根本不会让缓存的 client 失效。
  ///
  /// 正确做法：创建一个**全新的** `IOHttpClientAdapter`，让 Dio 换掉整个
  /// adapter。这样 Dio 会重新走 `_createHttpClient()`，新 client 生效。
  static void _replaceAdapter(Dio dio, void Function(HttpClient) configure) {
    final previous = dio.httpClientAdapter;
    final adapter = IOHttpClientAdapter();
    final client = HttpClient();
    configure(client);
    adapter.createHttpClient = () => client;

    dio.httpClientAdapter = adapter;
    // 旧 adapter 的 client 需关闭，否则 socket 泄漏。
    // 用非 force 的 close：让正在进行的请求自然结束。
    if (previous is IOHttpClientAdapter) {
      previous.close();
    }
  }

  /// 清除代理：换回一个不带代理配置的全新 adapter。
  static void _clearProxy(Dio dio) {
    final previous = dio.httpClientAdapter;
    dio.httpClientAdapter = IOHttpClientAdapter();
    if (previous is IOHttpClientAdapter) {
      previous.close();
    }
  }
}

/// 带缓冲的 socket 字节读取器。
///
/// SOCKS5 握手是"请求-应答"式协议，必须精确读取固定长度的字段。
/// `socket.listen` 的 chunk 边界与协议字段边界无关，因此需要一个
/// 自己维护缓冲区的读取器。
class _ByteReader {
  _ByteReader(Socket socket) {
    _subscription = socket.listen(
      (chunk) {
        if (_forwarding) {
          _controller.add(chunk);
        } else {
          _buffer.addAll(chunk);
        }
        _signal();
      },
      onError: (Object error, StackTrace stack) {
        _error = error;
        if (_forwarding) _controller.addError(error, stack);
        _signal();
      },
      onDone: () {
        _done = true;
        if (_forwarding) _controller.close();
        _signal();
      },
    );
  }

  final List<int> _buffer = <int>[];
  late final StreamSubscription<Uint8List> _subscription;
  Completer<void>? _waiter;
  Object? _error;
  bool _done = false;

  /// 握手完成后把收到的数据转发给下游（例如 HttpClient）。
  ///
  /// dart:io 的 `Socket` 只能被订阅一次，握手阶段已经用掉了这次机会，
  /// 所以数据必须通过**同一个**订阅往下传。
  ///
  /// [_forwarding] 为 true 时，新到的数据直接进入 [_controller]；
  /// 为 false 时（握手中）先进 [_buffer]，由 [readExactly] 消费。
  ///
  /// 顺序保证：[startForwarding] 内的两步是同步的，Dart 单 isolate 下
  /// 事件循环不会在中间插入 socket 事件，因此"缓冲区里的旧数据"一定
  /// 先于"新到达的数据"进入 [_controller]。
  final StreamController<Uint8List> _controller =
      StreamController<Uint8List>();
  bool _forwarding = false;

  /// 切换到转发模式，并把 [_buffer] 中剩余的字节交给下游。
  ///
  /// 必须在下游开始消费之前调用，否则"握手应答与首字节同包到达"时
  /// 会丢掉尾随字节。
  void startForwarding() {
    if (_forwarding) return;
    _forwarding = true;
    if (_buffer.isEmpty) return;
    final leftover = Uint8List.fromList(_buffer);
    _buffer.clear();
    _controller.add(leftover);
  }

  /// 下游数据流（握手完成后由 HttpClient 订阅）。
  Stream<Uint8List> get stream => _controller.stream;

  /// 停止向下游转发（交给 TLS 层接管订阅时调用）。
  ///
  /// 调用后新到的数据**不再**进入 [_controller]，但仍会被 [_buffer]
  /// 缓存起来，避免丢字节。
  void stopForwarding() {
    _forwarding = false;
  }

  void _signal() {
    final waiter = _waiter;
    if (waiter != null && !waiter.isCompleted) {
      _waiter = null;
      waiter.complete();
    }
  }

  /// 精确读取 [count] 个字节。
  Future<List<int>> readExactly(int count) async {
    while (_buffer.length < count) {
      if (_error != null) {
        throw _error!;
      }
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

  /// 交出 socket 所有权：取消监听但保留已缓冲的数据。
  @Deprecated('dart:io 的 Socket 是单订阅流，取消后无法再次订阅；'
      '请使用 [Socks5Tunnel.asSocket] 或交给 SecureSocket.secure 接管订阅')
  Future<void> detach() async {
    await _subscription.cancel();
  }

  void cancel() {
    _subscription.cancel();
  }
}

/// SOCKS5 握手成功后的隧道。
///
/// 持有握手用的 socket 与**仍在运行的**订阅。
class Socks5Tunnel {
  // 构造函数私有：[_ByteReader] 是私有类型，若构造函数公开，
  // 分析器会报 `library_private_types_in_public_api`（lint）。
  // 唯一的创建入口是 [ProxySelector.openSocks5Tunnel]。
  Socks5Tunnel._(this.socket, this._reader);

  /// 底层 socket（到目标站点的隧道）。
  ///
  /// https 目标请交给 [upgradeToTls]，它会接管 [_reader] 的订阅。
  final Socket socket;

  final _ByteReader _reader;

  /// 把隧道升级为 TLS 连接。
  ///
  /// [SecureSocket.secure] 内部调用 `socket._detachRaw()`，并把
  /// **现有的** stream subscription 一并接管
  /// （dart-sdk `lib/io/secure_socket.dart:152-174`）。
  /// 因此握手用的监听不会被取消，HttpClient 之后可以正常订阅新的
  /// [SecureSocket]（它是一个全新的 `_Socket`，包裹在 detached 的
  /// `RawSecureSocket` 之上）。
  ///
  /// 调用前必须先 [stopForwarding]，避免 reader 与 TLS 层同时消费
  /// 同一批字节。
  Future<SecureSocket> upgradeToTls(String host) async {
    _reader.stopForwarding();
    return SecureSocket.secure(
      socket,
      host: host,
      onBadCertificate: ProxySelector.certificateValidator,
    );
  }

  /// 把隧道包装成一个可供 `HttpClient` 使用的 [Socket]。
  ///
  /// dart:io 的 `Socket` 是单订阅流，握手阶段已经订阅过一次，
  /// 因此不能直接把 [socket] 交给 HttpClient（会抛
  /// `StateError: Stream has already been listened to`）。
  /// [_TunnelSocket] 把**同一个订阅**的数据转发给 HttpClient，
  /// 从而既保留订阅所有权，又能正常收发 HTTP 流量。
  Socket asSocket() {
    _reader.startForwarding();
    return _TunnelSocket(socket, _reader);
  }

  /// 关闭隧道（连接失败或请求取消时调用）。
  void destroy() {
    _reader.cancel();
    socket.destroy();
  }
}

/// 把 SOCKS5 隧道的单个订阅包装成 `HttpClient` 可用的 [Socket]。
///
/// `Socket` 是 `abstract interface class`，实现 `Stream<Uint8List>` 与
/// `IOSink`（dart-sdk `lib/io/socket.dart:836`）。
///
/// 读方向：把 [_reader] 收到的数据转发给订阅者。
/// 写方向：直接写入底层 socket。
///
/// 实现方式：`extends Stream<Uint8List>` 让 `Stream` 的所有成员
/// （`map` / `where` / `fold` / ... ）自动基于本类的 `listen` 实现，
/// 无需逐个手写。
class _TunnelSocket extends Stream<Uint8List> implements Socket {
  _TunnelSocket(this._socket, this._reader);

  final Socket _socket;
  final _ByteReader _reader;

  final StreamController<Uint8List> _controller =
      StreamController<Uint8List>();
  StreamSubscription<Uint8List>? _forward;

  void _ensureForwarding() {
    _forward ??= _reader.stream.listen(
      _controller.add,
      onError: _controller.addError,
      onDone: _controller.close,
    );
  }

  @override
  StreamSubscription<Uint8List> listen(
    void Function(Uint8List event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    _ensureForwarding();
    return _controller.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  // ---- 写方向：直接委托给底层 socket ----

  @override
  set encoding(Encoding value) => _socket.encoding = value;

  @override
  Encoding get encoding => _socket.encoding;

  @override
  void write(Object? object) => _socket.write(object);

  @override
  void writeln([Object? object = '']) => _socket.writeln(object);

  @override
  void writeCharCode(int charCode) => _socket.writeCharCode(charCode);

  @override
  void writeAll(Iterable objects, [String separator = '']) =>
      _socket.writeAll(objects, separator);

  @override
  void add(List<int> bytes) => _socket.add(bytes);

  @override
  void addError(Object error, [StackTrace? stackTrace]) =>
      _socket.addError(error, stackTrace);

  @override
  Future<void> addStream(Stream<List<int>> stream) =>
      _socket.addStream(stream);

  @override
  Future<void> flush() => _socket.flush();

  @override
  Future<void> close() => _socket.close();

  @override
  Future<void> get done => _socket.done;

  @override
  void destroy() {
    _forward?.cancel();
    _reader.cancel();
    _socket.destroy();
  }

  // ---- 只读属性 ----

  @override
  int get port => _socket.port;

  @override
  int get remotePort => _socket.remotePort;

  @override
  InternetAddress get address => _socket.address;

  @override
  InternetAddress get remoteAddress => _socket.remoteAddress;

  @override
  bool setOption(SocketOption option, bool enabled) =>
      _socket.setOption(option, enabled);

  @override
  Uint8List getRawOption(RawSocketOption option) =>
      _socket.getRawOption(option);

  @override
  void setRawOption(RawSocketOption option) =>
      _socket.setRawOption(option);
}
