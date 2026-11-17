// Copyright 2026 WITHLET11 <withlet11@gmail.com>
// SPDX-License-Identifier: MIT

import 'note_title.dart';

String markdownExportFileName(String content) {
  var fileName = deriveNoteTitle(content)
      .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_')
      .replaceAll(RegExp(r'[. ]+$'), '')
      .trim();

  if (fileName.isEmpty) {
    fileName = 'Untitled';
  }

  // Avoid reserved filenames on Windows, too.
  if (RegExp(
    r'^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])$',
    caseSensitive: false,
  ).hasMatch(fileName)) {
    fileName = '_$fileName';
  }

  return '$fileName.md';
}
