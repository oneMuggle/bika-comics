// Probe the LIVE Pica API using the APP'S OWN SHIPPING signing code.
//
// Why this file exists
// --------------------
// Prior batches (batch59-62) concluded the API host was unreachable and
// validated the signing code only against DESKTOP SOURCE. That was wrong on
// two counts, both established by this batch:
//
//   1. The host IS reachable. A request that fails auth returns a structured
//      body {"code":401,"error":"1005","message":"unauthorized"} -- that is an
//      ANSWER, not a timeout. A wrong path returns HTTP 404. A wrong key
//      header returns 401. Only a genuinely unreachable host times out.
//
//   2. The mobile signing constants match the desktop BYTE FOR BYTE
//      (sha256 of the app secret is identical on both sides), so any
//      difference in outcome must come from something else.
//
// This probe therefore drives the exact code the app ships:
//   lib/core/api/api_signature.dart  -> ApiSignature.normalizeSignedPath
//                                        ApiSignature.buildHeaders
//
// and reports, per candidate base URL, the HTTP status + the response body.
//
// It also runs a CONTROL with a deliberately WRONG signature, so a pass
// cannot be confused with "the server ignores auth entirely".
//
// Run:  dart run tool/probe_app_client.dart
// Exit: 0 = at least one base URL returned a usable JSON body.
//       2 = every candidate failed (see output).

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../lib/core/api/api_signature.dart';

/// Candidate base URLs. The jpacg mirrors expect the upstream host as a
/// PATH PREFIX (https://bika-api.jpacg.cc/picaapi.picacomic.com/comics?page=1);
/// the bare mirror returns HTTP 404.
const candidates = <String>[
  'https://picaapi.picacomic.com',
  'https://bika-api.jpacg.cc/picaapi.picacomic.com',
  'https://bika2-api.jpacg.cc/picaapi.picacomic.com',
];

/// Endpoints worth probing (relative, no leading slash -- same as desktop).
const probes = <String, String>{
  'comics': 'comics?page=1',
  'categories': 'categories',
  'init': 'init?platform=android',
};

Dio buildClient(String baseUrl, {bool corruptSignature = false}) {
  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 30),
    responseType: ResponseType.json,
    headers: {'accept': ApiSignature.accept},
  ));
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      // EXACTLY what lib/core/api/api_client.dart::_AuthInterceptor does.
      final signedPath =
          ApiSignature.normalizeSignedPath(options.uri, options.baseUrl);
      if (signedPath != null) {
        final signed = ApiSignature.buildHeaders(
          path: signedPath,
          method: options.method.toUpperCase(),
        );
        signed.forEach((k, v) => options.headers[k] = v);
        if (corruptSignature) {
          // CONTROL: deliberately break the signature so we can tell an
          // auth-gated endpoint from one that ignores the header entirely.
          options.headers['signature'] = '0' * 64;
        }
      }
      handler.next(options);
    },
  ));
  return dio;
}

Future<Map<String, dynamic>> fetch(Dio dio, String path) async {
  try {
    final r = await dio.get<dynamic>(path);
    final body = r.data;
    return {
      'status': r.statusCode,
      'ok': true,
      'body': body is Map ? body : jsonEncode(body),
    };
  } on DioException catch (e) {
    final resp = e.response;
    return {
      'status': resp?.statusCode ?? -1,
      'ok': false,
      'error': e.type.name,
      'body': resp?.data is Map ? resp!.data : (resp?.data ?? e.message),
    };
  }
}

/// Summary of the shape of a JSON body, without dumping the whole thing.
String summarize(Object? body) {
  if (body is! Map) return 'non-map body: ${body.toString().substring(0, 120)}';
  final b = body;
  final code = b['code'];
  final data = b['data'];
  final keys = b.keys.toList()..sort();
  var extra = '';
  if (data is Map) {
    final dk = data.keys.toList()..sort();
    extra = ' data.keys=${dk.take(8).toList()}';
    final comics = data['comics'];
    if (comics is List) extra += ' comics=${comics.length}';
    final cats = data['categories'];
    if (cats is List) extra += ' categories=${cats.length}';
  }
  return 'code=$code keys=$keys$extra';
}

Future<void> main() async {
  var anyUsable = false;
  var anyAuthed = false;

  for (final base in candidates) {
    stdout.writeln('=' * 74);
    stdout.writeln('BASE: $base');
    stdout.writeln('=' * 74);
    final dio = buildClient(base);
    final dioBad = buildClient(base, corruptSignature: true);

    for (final entry in probes.entries) {
      // Run twice: once with the shipping signature, once with a corrupted
      // one. If BOTH succeed, the endpoint is not auth-gated and the
      // signature proves nothing; if only the real one succeeds, the
      // shipping signing code is genuinely correct.
      final good = await fetch(dio, entry.value);
      final bad = await fetch(dioBad, entry.value);

      stdout.writeln('  ${entry.key}');
      stdout.writeln('    shipping-signature: status=${good['status']} '
          '${summarize(good['body'])}');
      stdout.writeln('    corrupted-control : status=${bad['status']} '
          '${summarize(bad['body'])}');

      if (good['status'] == 200) {
        anyUsable = true;
        if (bad['status'] != 200) anyAuthed = true;
      }
    }
    dio.close(force: true);
    dioBad.close(force: true);
    stdout.writeln('');
  }

  stdout.writeln('=' * 74);
  stdout.writeln('RESULT usable=$anyUsable signature_matters=$anyAuthed');
  if (!anyUsable) {
    stdout.writeln('NO BASE URL RETURNED 200');
    exitCode = 2;
  }
}
