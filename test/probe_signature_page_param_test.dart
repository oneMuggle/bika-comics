
import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picacg_flutter/core/storage/secure_storage.dart';
import 'package:picacg_flutter/core/storage/settings_storage.dart';
import 'package:picacg_flutter/features/comic/data/comic_repository.dart';

void main() {
  setUpAll(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    SecureStorageHolder.instance = SecureStorage(const FlutterSecureStorage());
    SettingsStorageHolder.instance = SettingsStorage(const FlutterSecureStorage());
  });

  test('PROBE', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final cap = <String>[];
    final t = <String>[];
    final n = <String>[];
    final sg = <String>[];
    server.listen((HttpRequest request) async {
      cap.add(request.uri.toString());
      t.add(request.headers.value('time') ?? '');
      n.add(request.headers.value('nonce') ?? '');
      sg.add(request.headers.value('signature') ?? '');
      request.response
        ..statusCode = 200
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({
          'error': {'code': 0},
          'data': {'eps': {'docs': [], 'total': 0, 'pages': 1, 'limit': 200, 'page': 1}}
        }));
      await request.response.close();
    });
    SettingsStorage.populateCache({'api_base_url': 'http://127.0.0.1:${server.port}/'});
    final repo = ComicRepository();
    await repo.getEpisodePage('abc123', page: 3);
    await server.close(force: true);
    // ignore: avoid_print
    print('PROBE_REQUEST_LINE=${cap.first}');
    // ignore: avoid_print
    print('PROBE_SIGNATURE=${sg.first}');
    // ignore: avoid_print
    print('PROBE_TIME=${t.first}');
    // ignore: avoid_print
    print('PROBE_NONCE=${n.first}');
  });
}
