// Copyright 2026 WITHLET11 <withlet11@gmail.com>
// SPDX-License-Identifier: MIT

String deriveNoteTitle(String content) {
  for (final line in content.split('\n')) {
    final trimmedLine = line.trim();

    if (trimmedLine.isEmpty) {
      continue;
    }

    final title = trimmedLine.replaceFirst(RegExp(r'^#{1,6}\s*'), '').trim();

    return title.isEmpty ? 'Untitled' : title;
  }

  return 'Untitled';
}
