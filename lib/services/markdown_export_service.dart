// Copyright 2026 WITHLET11 <withlet11@gmail.com>
// SPDX-License-Identifier: MIT

import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../models/note.dart';
import '../utils/markdown_export_file_name.dart';

typedef MarkdownFileSaver = Future<String?> Function({
  required String fileName,
  required Uint8List bytes,
});

class MarkdownExportService {
  MarkdownExportService({MarkdownFileSaver? saveFile})
    : _saveFile = saveFile ?? _saveWithFilePicker;

  final MarkdownFileSaver _saveFile;

  Future<String?> exportNote(Note note) {
    final fileName = markdownExportFileName(note.content);
    final bytes = Uint8List.fromList(utf8.encode(note.content));

    return _saveFile(fileName: fileName, bytes: bytes);
  }
}

Future<String?> _saveWithFilePicker({
  required String fileName,
  required Uint8List bytes,
}) async {
  final uri = await FilePicker.saveFile(
    fileName: fileName,
    bytes: bytes,
    mimeType: 'text/markdown',
    dialogTitle: 'Export Markdown note',
  );

  return uri?.toString();
}
