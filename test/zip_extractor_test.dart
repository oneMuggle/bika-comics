import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picacg_flutter/features/nas/data/zip_extractor.dart';

void main() {
  group('ZipExtractor.extract', () {
    test('returns failure for non-existent file', () async {
      final result = await ZipExtractor.extract('/tmp/definitely-not-real.zip');
      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('文件不存在'));
      expect(result.firstErrorCode, ZipExtractor.errIo);
    });

    test('returns failure for non-zip file (random bytes)', () async {
      // Create a temp file with random bytes that are NOT a valid ZIP
      final tmp = await Directory.systemTemp.createTemp('zip_test_');
      try {
        final file = File('${tmp.path}/bad.zip');
        await file.writeAsBytes(Uint8List.fromList(List.generate(64, (i) => i * 3 % 256)));
        final result = await ZipExtractor.extract(file.path);
        expect(result.isSuccess, isFalse);
        // 应该不是 errNotZip 也不是 errEncrypted，也不是 errIo (I/O 成功)
        // 解码报错是预期的，但具体错误码取决于 archive 包
        expect(result.errorMessage, isNotNull);
      } finally {
        await tmp.delete(recursive: true);
      }
    });

    test('extracts a valid ZIP archive with images in subdirectory', () async {
      // Create a ZIP with images in a subdirectory
      final archive = Archive();
      // 5 张图片，命名带数字前缀
      for (var i = 1; i <= 5; i++) {
        // 最小 PNG：1x1 红色像素
        const tinyPng = <int>[
          0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
          0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR length+type
          0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, // 1x1
          0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, // bit depth, color type, etc.
          0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41, // IDAT length+type
          0x54, 0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
          0x00, 0x00, 0x03, 0x00, 0x01, 0x5B, 0x6F, 0x80,
          0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, // IEND
          0x44, 0xAE, 0x42, 0x60, 0x82,
        ];
        archive.addFile(ArchiveFile(
          'pages/${i.toString().padLeft(3, '0')}.png',
          tinyPng.length,
          Uint8List.fromList(tinyPng),
        ));
      }
      // 加上一个无关文件在根目录
      archive.addFile(ArchiveFile('readme.txt', 5, Uint8List.fromList('hello'.codeUnits)));

      final zipBytes = ZipEncoder().encode(archive)!;
      final tmp = await Directory.systemTemp.createTemp('zip_test_');
      try {
        final file = File('${tmp.path}/good.cbz');
        await file.writeAsBytes(zipBytes);
        final result = await ZipExtractor.extract(file.path);
        expect(result.isSuccess, isTrue, reason: result.errorMessage);
        expect(result.entries.length, 5);
        // 应该是自然顺序：001 < 002 < ... < 005
        expect(result.entries[0].entryName, 'pages/001.png');
        expect(result.entries[4].entryName, 'pages/005.png');
        // 字节应该非空
        for (final e in result.entries) {
          expect(e.bytes.length, greaterThan(0));
        }
      } finally {
        await tmp.delete(recursive: true);
      }
    });

    test('handles ZIP with images in root directory', () async {
      final archive = Archive();
      const tinyPng = <int>[
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
        0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,
        0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41,
        0x54, 0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
        0x00, 0x00, 0x03, 0x00, 0x01, 0x5B, 0x6F, 0x80,
        0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E,
        0x44, 0xAE, 0x42, 0x60, 0x82,
      ];
      for (var i = 1; i <= 3; i++) {
        archive.addFile(ArchiveFile(
          '${i.toString().padLeft(2, '0')}.jpg',
          tinyPng.length,
          Uint8List.fromList(tinyPng),
        ));
      }
      final zipBytes = ZipEncoder().encode(archive)!;
      final tmp = await Directory.systemTemp.createTemp('zip_test_');
      try {
        final file = File('${tmp.path}/root_images.zip');
        await file.writeAsBytes(zipBytes);
        final result = await ZipExtractor.extract(file.path);
        expect(result.isSuccess, isTrue, reason: result.errorMessage);
        expect(result.entries.length, 3);
      } finally {
        await tmp.delete(recursive: true);
      }
    });

    test('returns failure when no images found', () async {
      final archive = Archive();
      archive.addFile(ArchiveFile('readme.txt', 5, Uint8List.fromList('hello'.codeUnits)));
      archive.addFile(ArchiveFile('notes.md', 5, Uint8List.fromList('world'.codeUnits)));
      final zipBytes = ZipEncoder().encode(archive)!;
      final tmp = await Directory.systemTemp.createTemp('zip_test_');
      try {
        final file = File('${tmp.path}/no_images.zip');
        await file.writeAsBytes(zipBytes);
        final result = await ZipExtractor.extract(file.path);
        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, contains('未发现图片'));
        expect(result.firstErrorCode, ZipExtractor.errNoImages);
      } finally {
        await tmp.delete(recursive: true);
      }
    });
  });
}
