// Copyright 2026 WITHLET11 <withlet11@gmail.com>
// SPDX-License-Identifier: MIT

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wl11_note/utils/markdown_formatting.dart';

void main() {
  group('Inline formatting', () {
    test('wraps selected text in bold markers', () {
      final result = applyMarkdownFormat(
        'Hello world',
        const TextSelection(baseOffset: 6, extentOffset: 11),
        MarkdownFormat.bold,
      );

      expect(result.text, 'Hello **world**');
      expect(result.selection.start, 8);
      expect(result.selection.end, 13);
    });

    test('inserts italic markers at cursor', () {
      final result = applyMarkdownFormat(
        'Hello ',
        const TextSelection.collapsed(offset: 6),
        MarkdownFormat.italic,
      );

      expect(result.text, 'Hello **');
      expect(result.selection, const TextSelection.collapsed(offset: 7));
    });

    test('wraps selected text in strikethrough markers', () {
      final result = applyMarkdownFormat(
        'Hello world',
        const TextSelection(baseOffset: 6, extentOffset: 11),
        MarkdownFormat.strikethrough,
      );

      expect(result.text, 'Hello ~~world~~');
    });

    test('inserts inline code markers at cursor', () {
      final result = applyMarkdownFormat(
        '',
        const TextSelection.collapsed(offset: 0),
        MarkdownFormat.inlineCode,
      );

      expect(result.text, '``');
      expect(result.selection, const TextSelection.collapsed(offset: 1));
    });

    test('wraps selected text in inline code markers', () {
      final result = applyMarkdownFormat(
        'print()',
        const TextSelection(baseOffset: 0, extentOffset: 7),
        MarkdownFormat.inlineCode,
      );

      expect(result.text, '`print()`');
      expect(
        result.selection,
        const TextSelection(baseOffset: 1, extentOffset: 8),
      );
    });
  });

  group('Link formatting', () {
    test('creates a link around selected text', () {
      final result = applyMarkdownFormat(
        'Example',
        const TextSelection(baseOffset: 0, extentOffset: 7),
        MarkdownFormat.link,
      );

      expect(result.text, '[Example](url)');
      expect(
        result.selection,
        const TextSelection(baseOffset: 10, extentOffset: 13),
      );
    });

    test('inserts a link placeholder at cursor', () {
      final result = applyMarkdownFormat(
        '',
        const TextSelection.collapsed(offset: 0),
        MarkdownFormat.link,
      );

      expect(result.text, '[text](url)');
      expect(
        result.selection,
        const TextSelection(baseOffset: 1, extentOffset: 5),
      );
    });
  });

  group('Block formatting', () {
    test('creates a bulleted list', () {
      final result = applyMarkdownFormat(
        'First\nSecond',
        const TextSelection(baseOffset: 0, extentOffset: 12),
        MarkdownFormat.bulletedList,
      );

      expect(result.text, '- First\n- Second');
    });

    test('creates an incrementing numbered list', () {
      final result = applyMarkdownFormat(
        'First\nSecond\nThird',
        const TextSelection(baseOffset: 0, extentOffset: 18),
        MarkdownFormat.numberedList,
      );

      expect(result.text, '1. First\n2. Second\n3. Third');
    });

    test('creates a blockquote', () {
      final result = applyMarkdownFormat(
        'First\nSecond',
        const TextSelection(baseOffset: 0, extentOffset: 12),
        MarkdownFormat.blockquote,
      );

      expect(result.text, '> First\n> Second');
    });

    test('wraps selected text in a code block', () {
      final result = applyMarkdownFormat(
        'print("Hello")',
        const TextSelection(baseOffset: 0, extentOffset: 14),
        MarkdownFormat.codeBlock,
      );

      expect(result.text, '```\nprint("Hello")\n```');
    });

    test('inserts a horizontal rule', () {
      final result = applyMarkdownFormat(
        'First',
        const TextSelection.collapsed(offset: 5),
        MarkdownFormat.horizontalRule,
      );

      expect(result.text, 'First\n---\n');
    });
  });
}
