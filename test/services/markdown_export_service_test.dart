// Copyright 2026 WITHLET11 <withlet11@gmail.com>
// SPDX-License-Identifier: MIT

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:wl11_note/models/note.dart';
import 'package:wl11_note/services/markdown_export_service.dart';

void main() {
  group('MarkdownExportService', () {
    late String capturedFileName;
    late Uint8List capturedBytes;

    final now = DateTime(2026, 1, 1);

    test('exports the original Markdown content', () async {
      const content = '# 日本語のノート\n\n**Important** text.\n';

      final note = Note(
        id: 'test-note',
        content: content,
        createdAt: now,
        updatedAt: now,
      );

      final service = MarkdownExportService(
        saveFile: ({required String fileName, required Uint8List bytes}) async {
          capturedFileName = fileName;
          capturedBytes = bytes;
          return '/tmp/Japanese note.md';
        },
      );

      final result = await service.exportNote(note);

      expect(result, '/tmp/Japanese note.md');
      expect(capturedFileName, '日本語のノート.md');
      expect(utf8.decode(capturedBytes), content);
    });

    test('returns null when the user cancels', () async {
      final note = Note(
        id: 'test-note',
        content: '# Test note',
        createdAt: now,
        updatedAt: now,
      );

      final service = MarkdownExportService(
        saveFile: ({required String fileName, required Uint8List bytes}) async {
          return null;
        },
      );

      expect(await service.exportNote(note), isNull);
    });
  });
}
