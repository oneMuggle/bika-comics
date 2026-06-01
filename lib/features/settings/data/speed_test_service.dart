/// 网络测速服务
///
/// 桌面端对应:
///   - `SpeedTestReq`     — 测速（下载静态资源测速）
///   - `SpeedTestPingReq` — Ping（请求 /categories 接口测延迟）
///
/// 详见 src/server/req.py

import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../shared/constants/api_constants.dart';

class SpeedTestResult {
  final double speedKBps;
  final int pingMs;
  final String? error;

  const SpeedTestResult({
    required this.speedKBps,
    required this.pingMs,
    this.error,
  });

  bool get isOk => error == null;
}

class SpeedTestService {
  final Dio _api = ApiClient.instance;

  /// Ping 测试：请求 /categories 测量延迟
  ///
  /// 桌面端: `SpeedTestPingReq`
  Future<int> ping({int samples = 3}) async {
    final times = <int>[];
    for (int i = 0; i < samples; i++) {
      final stopwatch = Stopwatch()..start();
      try {
        await _api.get(
          ApiEndpoints.categories,
          options: Options(
            headers: {
              'cache-control': 'no-cache',
              'expires': '0',
              'pragma': 'no-cache',
              'authorization': '',
            },
          ),
        );
      } catch (_) {
        // 即使失败，也记录已经过去的时间
      }
      stopwatch.stop();
      times.add(stopwatch.elapsedMilliseconds);
    }
    if (times.isEmpty) return -1;
    times.sort();
    return times.first; // 取最小延迟
  }

  /// 测速：下载静态资源并计算速度 (KB/s)
  ///
  /// 桌面端: `SpeedTestReq`
  Future<double> downloadSpeed({
    String url =
        'https://storage1.picacomic.com/static/fc75975a-af8e-40c5-8679-725d6f64d6f5.jpg',
  }) async {
    final stopwatch = Stopwatch()..start();
    int bytes = 0;
    try {
      final response = await Dio().get<ResponseBody>(
        url,
        options: Options(responseType: ResponseType.stream),
      );
      final stream = response.data;
      if (stream == null) return 0;
      final completer = Completer<void>();
      final sub = stream.stream.listen(
        (chunk) => bytes += chunk.length,
        onError: (e) => completer.complete(),
        onDone: () => completer.complete(),
        cancelOnError: true,
      );
      await completer.future.timeout(const Duration(seconds: 30));
      await sub.cancel();
    } on TimeoutException {
      // 超时也返回当前已读取的字节
    } on DioException catch (e) {
      if (e.type != DioExceptionType.cancel &&
          e.type != DioExceptionType.connectionTimeout) {
        // 网络错误
      }
    } on SocketException {
      // 网络不可达
    }
    stopwatch.stop();
    if (stopwatch.elapsedMilliseconds == 0) return 0;
    final seconds = stopwatch.elapsedMilliseconds / 1000.0;
    return bytes / 1024.0 / seconds;
  }

  /// 综合测速：ping + download
  Future<SpeedTestResult> runFull() async {
    try {
      final pingMs = await ping();
      final speed = await downloadSpeed();
      return SpeedTestResult(speedKBps: speed, pingMs: pingMs);
    } catch (e) {
      return SpeedTestResult(
        speedKBps: 0,
        pingMs: -1,
        error: e.toString(),
      );
    }
  }
}

final speedTestServiceProvider = Provider<SpeedTestService>((ref) {
  return SpeedTestService();
});

/// 综合测速 FutureProvider
final speedTestProvider = FutureProvider<SpeedTestResult>((ref) async {
  return ref.read(speedTestServiceProvider).runFull();
});
