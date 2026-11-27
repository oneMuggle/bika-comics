// Print the MOBILE's RUNTIME signing/header constants.
//
// Purpose: diff these against the desktop's runtime constants
// (tool/dump_desktop_runtime.py) to find byte-level drift that
// source-reading hides -- e.g. the mobile stores the app secret in a Dart
// RAW string, where a backslash pair is TWO literal backslashes, while the
// desktop's Python non-raw string may yield ONE literal backslash.
//
// Run:  dart run tool/dump_mobile_runtime.dart
// Emits a DESKTOP_RUNTIME_JSON-shaped payload on stdout for diffing.

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import '../lib/core/api/api_signature.dart';

void main() {
  const secret = ApiSignature.appSecret;

  final sha256Of = sha256.convert(utf8.encode(secret)).toString();
  final backslashes = '\\'.allMatches(secret).length;

  final lines = <String>[];
  lines.add('== mobile app secret ==');
  lines.add('  escaped    : ' + secret.replaceAll('\\', '\\\\'));
  lines.add('  length     : ' + secret.length.toString());
  lines.add('  backslashes: ' + backslashes.toString());
  lines.add('  sha256     : ' + sha256Of);
  lines.add('');
  lines.add('== mobile header constants ==');
  lines.add('  accept          : ' + ApiSignature.accept);
  lines.add('  appChannel      : ' + ApiSignature.appChannel);
  lines.add('  appUuid         : ' + ApiSignature.appUuid);
  lines.add('  appVersion      : ' + ApiSignature.appVersion);
  lines.add('  appBuildVersion : ' + ApiSignature.appBuildVersion);
  lines.add('  appPlatform     : ' + ApiSignature.appPlatform);
  lines.add('  imageQuality    : ' + ApiSignature.imageQuality);
  lines.add('  userAgent       : ' + ApiSignature.userAgent);
  lines.add('  clientVersion   : ' + ApiSignature.clientVersion);
  lines.add('');

  final payload = <String, dynamic>{
    'secret': secret,
    'secret_len': secret.length,
    'secret_backslashes': backslashes,
    'secret_sha256': sha256Of,
    'config': <String, String>{
      'ApiKey': ApiSignature.apiKey,
      'Accept': ApiSignature.accept,
      'AppChannel': ApiSignature.appChannel,
      'Uuid': ApiSignature.appUuid,
      'Version': ApiSignature.appVersion,
      'ImageQuality': ApiSignature.imageQuality,
      'Platform': ApiSignature.appPlatform,
      'BuildVersion': ApiSignature.appBuildVersion,
      'Agent': ApiSignature.userAgent,
      'UpdateVersion': ApiSignature.clientVersion,
    },
  };

  stdout.writeln(lines.join('\n'));
  stdout.writeln('DESKTOP_RUNTIME_JSON ' + jsonEncode(payload));
}
