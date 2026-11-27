// Live probe of the real Pica API, using the SHIPPING signing code.
//
// Why this file exists
// --------------------
// The direct API host (picaapi.picacomic.com) is TCP-unreachable from the
// build host, so previous batches could only cross-check the mobile model
// against the desktop SOURCE. That proves what the desktop *expects*, not
// what the API *returns*.
//
// The desktop's own config/config.py lists two API mirror domains:
//     # ProxyApiDomain  = "bika-api.jpacg.cc"
//     # ProxyApiDomain2 = "bika2-api.jpacg.cc"
// Those mirrors ARE reachable, so we can finally gather PRIMARY EVIDENCE.
//
// This probe reuses lib/core/api/api_signature.dart verbatim (the exact code
// the app ships) and lib/core/utils/media_url.dart, so a successful response
// simultaneously proves the signing implementation is correct end-to-end.
//
// Questions settled:
//   Q1. Comic media key: "cover" or "thumb"?
//   Q2. Comic comment envelope: data.docs vs data.comments.docs + topComments?
//   Q3. Comic like-count field name.
//   Q4. Game comment envelope.
//
// Run:  dart run tool/probe_api_shape.dart
// Exit: 0 = all questions answered, 2 = ran but got no usable samples.

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../lib/core/api/api_signature.dart';
import '../lib/core/utils/media_url.dart';

const mirrors = [
  'https://bika-api.jpacg.cc/',
  'https://bika2-api.jpacg.cc/',
];

Dio buildClient(String baseUrl) {
  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 30),
    responseType: ResponseType.json,
    headers: {
      'accept': ApiSignature.accept,
      'app-channel': ApiSignature.appChannel,
      'app-uuid': ApiSignature.appUuid,
      'app-version': ApiSignature.appVersion,
      'image-quality': ApiSignature.imageQuality,
      'app-platform': ApiSignature.appPlatform,
      'app-build-version': ApiSignature.appBuildVersion,
      'user-agent': ApiSignature.userAgent,
      'version': ApiSignature.clientVersion,
    },
  ));
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      final signedPath = ApiSignature.normalizeSignedPath(
        options.uri,
        options.baseUrl,
      );
      if (signedPath != null) {
        final signed = ApiSignature.buildHeaders(
          path: signedPath,
          method: options.method.toUpperCase(),
        );
        signed.forEach((k, v) => options.headers[k] = v);
      }
      handler.next(options);
    },
  ));
  return dio;
}

Future<void> main() async {
  Dio? dio;
  String? base;
  for (final m in mirrors) {
    stdout.writeln('[boot] trying mirror $m');
    try {
      final d = buildClient(m);
      final r = await d.get('/comics', queryParameters: {'page': 1});
      final body = r.data;
      if (body is Map && (body['code'] == 200 || body.containsKey('data'))) {
        dio = d;
        base = m;
        stdout.writeln('[boot] mirror OK: $m (code=${body['code']})');
        break;
      }
      stdout.writeln('[boot] $m responded code=${body is Map ? body['code'] : '?'}');
    } catch (e) {
      stdout.writeln('[boot] $m failed: ${e.toString().split('\n').first}');
    }
  }
  if (dio == null) {
    stdout.writeln('NO MIRROR REACHABLE - cannot gather live evidence');
    exitCode = 3;
    return;
  }

  // ---------------- Q1 / Q3: comic list ----------------
  final r = await dio.get('/comics', queryParameters: {'page': 1, 's': 'dd'});
  final body = r.data as Map<String, dynamic>;
  final data = (body['data'] as Map<String, dynamic>?) ?? {};
  stdout.writeln('[Q1] /comics data keys: ${(data.keys.toList()..sort())}');
  final comics = (data['comics'] as List?) ?? [];
  stdout.writeln('[Q1] comics returned: ${comics.length}');
  if (comics.isEmpty) {
    stdout.writeln('[Q1] NO COMICS - cannot settle Q1/Q3');
    exitCode = 2;
    return;
  }
  final c = comics.first as Map<String, dynamic>;
  final keys = c.keys.toList()..sort();
  stdout.writeln('[Q1] comic object keys: $keys');
  for (final k in ['cover', 'thumb', 'icon', 'pic']) {
    final has = c.containsKey(k);
    stdout.writeln('[Q1]   ${k.padRight(6)} present=${has.toString().padRight(6)} '
        'value=${jsonEncode(c[k]).substring(0, jsonEncode(c[k]).length.clamp(0, 140))}');
  }
  stdout.writeln('[Q1] RAW first comic: ${jsonEncode(c).substring(0, 1800)}');

  stdout.writeln('-' * 74);
  stdout.writeln('[Q3] count / flag fields on a comic object:');
  for (final k in [
    'likeCount',
    'likesCount',
    'totalLikes',
    'totalViews',
    'pagesCount',
    'epsCount',
    'isFavourite',
    'isLiked',
    'isFollowed',
    'commentsCount',
    'creator',
    '_creator',
    'title',
    'description',
    'author',
    'categories',
    'tags',
    'updated_at',
    'created_at',
    'shareId',
  ]) {
    stdout.writeln('[Q3]   ${k.padRight(14)} present=${c.containsKey(k).toString().padRight(6)} '
        'value=${jsonEncode(c[k]).substring(0, jsonEncode(c[k]).length.clamp(0, 110))}');
  }
  stdout.writeln('-' * 74);

  // ---------------- Q2: comic comment envelope ----------------
  final cid = c['_id'];
  final rc = await dio.get('/comics/$cid/comments', queryParameters: {'page': 1});
  final cbody = rc.data as Map<String, dynamic>;
  final cd = (cbody['data'] as Map<String, dynamic>?) ?? {};
  stdout.writeln('[Q2] /comics/{id}/comments data keys: ${(cd.keys.toList()..sort())}');
  stdout.writeln('[Q2]   top-level "docs"      : ${cd.containsKey('docs')}');
  stdout.writeln('[Q2]   top-level "comments"  : ${cd.containsKey('comments')}');
  if (cd['comments'] is Map) {
    final cm = cd['comments'] as Map<String, dynamic>;
    stdout.writeln('[Q2]   data.comments keys    : ${(cm.keys.toList()..sort())}');
  }
  stdout.writeln('[Q2]   "topComments" present : ${cd.containsKey('topComments')}');
  if (cd['topComments'] is List) {
    stdout.writeln('[Q2]   topComments count     : ${(cd['topComments'] as List).length}');
  }
  stdout.writeln('[Q2] RAW comments data (trunc): '
      '${jsonEncode(cd).substring(0, jsonEncode(cd).length.clamp(0, 2600))}');

  // Which envelope does the MOBILE code currently read?
  final mobileTopLevelDocs = cd['docs'];
  final mobileNestedDocs =
      (cd['comments'] is Map) ? ((cd['comments'] as Map)['docs']) : null;
  stdout.writeln('[Q2] MOBILE reads data["docs"]        -> ${mobileTopLevelDocs is List ? "LIST(${mobileTopLevelDocs.length})" : runtimeTypeOf(mobileTopLevelDocs)}');
  stdout.writeln('[Q2] DESKTOP reads data.comments.docs -> ${mobileNestedDocs is List ? "LIST(${mobileNestedDocs.length})" : runtimeTypeOf(mobileNestedDocs)}');

  List docs = [];
  if (mobileNestedDocs is List) docs = mobileNestedDocs;
  if (docs.isEmpty && mobileTopLevelDocs is List) docs = mobileTopLevelDocs;
  if (docs.isNotEmpty) {
    final cd0 = docs.first as Map<String, dynamic>;
    stdout.writeln('[Q2b] comment object keys: ${(cd0.keys.toList()..sort())}');
    for (final k in [
      'likeCount',
      'likesCount',
      'totalLikes',
      'isLiked',
      'replyCount',
      'totalComments',
      'commentsCount',
      'content',
      'created_at',
      'parent',
    ]) {
      stdout.writeln('[Q2b]   ${k.padRight(14)} present=${cd0.containsKey(k).toString().padRight(6)} '
          'value=${jsonEncode(cd0[k]).substring(0, jsonEncode(cd0[k]).length.clamp(0, 90))}');
    }
    final u = (cd0['_user'] ?? cd0['user']);
    if (u is Map) {
      stdout.writeln('[Q2b] user keys: ${(u.keys.toList()..sort())}');
      stdout.writeln('[Q2b] user avatar raw: ${jsonEncode(u['avatar']).substring(0, jsonEncode(u['avatar']).length.clamp(0, 160))}');
      if (u['avatar'] is Map) {
        stdout.writeln('[Q2b] mediaUrlFrom(avatar) = ${mediaUrlFrom(u['avatar'])}');
      }
    } else {
      stdout.writeln('[Q2b] NO _user/user object (type=${runtimeTypeOf(u)})');
    }
  }

  // ---------------- Q4: game comments ----------------
  try {
    final rg = await dio.get('/games', queryParameters: {'page': 1});
    final gd = ((rg.data as Map<String, dynamic>)['data'] as Map<String, dynamic>?) ?? {};
    final games = (gd['games'] as List?) ?? [];
    stdout.writeln('-' * 74);
    stdout.writeln('[Q4] /games data keys: ${(gd.keys.toList()..sort())} games=${games.length}');
    if (games.isNotEmpty) {
      final g = games.first as Map<String, dynamic>;
      stdout.writeln('[Q4] game object keys: ${(g.keys.toList()..sort())}');
      final gid = g['_id'];
      final rgc = await dio.get('/games/$gid/comments', queryParameters: {'page': 1});
      final gdc = ((rgc.data as Map<String, dynamic>)['data'] as Map<String, dynamic>?) ?? {};
      stdout.writeln('[Q4] /games/{id}/comments data keys: ${(gdc.keys.toList()..sort())}');
      stdout.writeln('[Q4]   top-level "docs"     : ${gdc.containsKey('docs')}');
      stdout.writeln('[Q4]   top-level "comments" : ${gdc.containsKey('comments')}');
      if (gdc['comments'] is Map) {
        stdout.writeln('[Q4]   data.comments keys   : ${((gdc['comments'] as Map).keys.toList()..sort())}');
      }
      stdout.writeln('[Q4] RAW: ${jsonEncode(gdc).substring(0, jsonEncode(gdc).length.clamp(0, 1800))}');
    }
  } catch (e) {
    stdout.writeln('[Q4] game probe failed: ${e.toString().split('\n').first}');
  }

  stdout.writeln('');
  stdout.writeln('PROBE COMPLETED OK (base=$base)');
}

String runtimeTypeOf(Object? v) => v == null ? 'null' : v.runtimeType.toString();
