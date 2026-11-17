// Copyright 2026 WITHLET11 <withlet11@gmail.com>
// SPDX-License-Identifier: MIT

import 'package:flutter/services.dart';

enum MarkdownFormat {
  bold,
  italic,
  strikethrough,
  link,
  bulletedList,
  numberedList,
  inlineCode,
  codeBlock,
  blockquote,
  horizontalRule,
}

class MarkdownEditResult {
  const MarkdownEditResult({required this.text, required this.selection});

  final String text;
  final TextSelection selection;
}

MarkdownEditResult applyMarkdownFormat(
  String text,
  TextSelection selection,
  MarkdownFormat format,
) {
  final start = selection.start.clamp(0, text.length);
  final end = selection.end.clamp(start, text.length);

  switch (format) {
    case MarkdownFormat.bold:
      return _wrap(text, start, end, '**', '**');

    case MarkdownFormat.italic:
      return _wrap(text, start, end, '*', '*');

    case MarkdownFormat.strikethrough:
      return _wrap(text, start, end, '~~', '~~');

    case MarkdownFormat.inlineCode:
      return _wrap(text, start, end, '`', '`');

    case MarkdownFormat.link:
      return _insertLink(text, start, end);

    case MarkdownFormat.bulletedList:
      return _prefixLines(text, start, end, '- ');

    case MarkdownFormat.numberedList:
      return _prefixNumberedLines(text, start, end);

    case MarkdownFormat.blockquote:
      return _prefixLines(text, start, end, '> ');

    case MarkdownFormat.codeBlock:
      return _wrapBlock(text, start, end);

    case MarkdownFormat.horizontalRule:
      return _insertHorizontalRule(text, start);
  }
}

MarkdownEditResult _wrap(
  String text,
  int start,
  int end,
  String prefix,
  String suffix,
) {
  final selectedText = text.substring(start, end);
  final replacement = '$prefix$selectedText$suffix';

  final result = text.replaceRange(start, end, replacement);

  final selectionStart = start + prefix.length;
  final selectionEnd = selectionStart + selectedText.length;

  return MarkdownEditResult(
    text: result,
    selection: start == end
        ? TextSelection.collapsed(offset: selectionStart)
        : TextSelection(baseOffset: selectionStart, extentOffset: selectionEnd),
  );
}

MarkdownEditResult _insertLink(String text, int start, int end) {
  const linkText = 'text';
  const url = 'url';

  final selectedText = text.substring(start, end);
  final displayText = selectedText.isEmpty ? linkText : selectedText;

  final replacement = '[$displayText]($url)';
  final result = text.replaceRange(start, end, replacement);

  if (selectedText.isEmpty) {
    return MarkdownEditResult(
      text: result,
      selection: TextSelection(
        baseOffset: start + 1,
        extentOffset: start + 1 + linkText.length,
      ),
    );
  }

  final urlStart = start + displayText.length + 3;

  return MarkdownEditResult(
    text: result,
    selection: TextSelection(
      baseOffset: urlStart,
      extentOffset: urlStart + url.length,
    ),
  );
}

MarkdownEditResult _prefixLines(
  String text,
  int start,
  int end,
  String prefix,
) {
  final lineStart = start == 0 ? 0 : text.lastIndexOf('\n', start - 1) + 1;

  final effectiveEnd = end > start && text[end - 1] == '\n' ? end - 1 : end;

  final newlineIndex = text.indexOf('\n', effectiveEnd);
  final lineEnd = newlineIndex == -1 ? text.length : newlineIndex;

  final block = text.substring(lineStart, lineEnd);
  final lines = block.split('\n');
  final replacement = lines.map((line) => '$prefix$line').join('\n');

  final result = text.replaceRange(lineStart, lineEnd, replacement);
  final addedLength = replacement.length - block.length;

  return MarkdownEditResult(
    text: result,
    selection: TextSelection(
      baseOffset: start + prefix.length,
      extentOffset: end + addedLength,
    ),
  );
}

MarkdownEditResult _prefixNumberedLines(String text, int start, int end) {
  final lineStart = start == 0 ? 0 : text.lastIndexOf('\n', start - 1) + 1;

  final effectiveEnd = end > start && text[end - 1] == '\n' ? end - 1 : end;

  final newlineIndex = text.indexOf('\n', effectiveEnd);
  final lineEnd = newlineIndex == -1 ? text.length : newlineIndex;

  final block = text.substring(lineStart, lineEnd);
  final lines = block.split('\n');

  final replacement = [
    for (var i = 0; i < lines.length; i++) '${i + 1}. ${lines[i]}',
  ].join('\n');

  final result = text.replaceRange(lineStart, lineEnd, replacement);
  final addedLength = replacement.length - block.length;

  return MarkdownEditResult(
    text: result,
    selection: TextSelection(
      baseOffset: start + 3,
      extentOffset: end + addedLength,
    ),
  );
}

MarkdownEditResult _wrapBlock(String text, int start, int end) {
  const prefix = '```\n';
  const suffix = '\n```';

  final selectedText = text.substring(start, end);
  final result = text.replaceRange(start, end, '$prefix$selectedText$suffix');

  if (start == end) {
    final cursor = start + prefix.length;

    return MarkdownEditResult(
      text: result,
      selection: TextSelection.collapsed(offset: cursor),
    );
  }

  return MarkdownEditResult(
    text: result,
    selection: TextSelection(
      baseOffset: start + prefix.length,
      extentOffset: start + prefix.length + selectedText.length,
    ),
  );
}

MarkdownEditResult _insertHorizontalRule(String text, int offset) {
  final insertion = offset == 0 || text[offset - 1] == '\n'
      ? '---\n'
      : '\n---\n';

  final result = text.replaceRange(offset, offset, insertion);

  final cursor = offset + insertion.length;

  return MarkdownEditResult(
    text: result,
    selection: TextSelection.collapsed(offset: cursor),
  );
}
