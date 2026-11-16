// Copyright 2026 WITHLET11 <withlet11@gmail.com>
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:wl11_note/utils/note_title.dart';

void main() {
  group('deriveNoteTitle', () {
    test('removes Markdown heading markers', () {
      expect(deriveNoteTitle('# My note'), 'My note');

      expect(deriveNoteTitle('## Shopping list'), 'Shopping list');
    });

    test('uses the first non-empty line', () {
      expect(deriveNoteTitle('\n\nFirst line\nSecond line'), 'First line');
    });

    test('trims surrounding whitespace', () {
      expect(deriveNoteTitle('  My note  '), 'My note');
    });

    test('returns Untitled for empty content', () {
      expect(deriveNoteTitle(''), 'Untitled');
      expect(deriveNoteTitle('  \n  '), 'Untitled');
      expect(deriveNoteTitle('#'), 'Untitled');
    });
  });
}
