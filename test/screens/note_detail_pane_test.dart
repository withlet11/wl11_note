// Copyright 2026 WITHLET11 <withlet11@gmail.com>
// SPDX-License-Identifier: MIT

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import 'package:wl11_note/database/app_database.dart';
import 'package:wl11_note/database/notes_dao.dart';
import 'package:wl11_note/database/tags_dao.dart';
import 'package:wl11_note/models/note.dart';
import 'package:wl11_note/providers/notes_provider.dart';
import 'package:wl11_note/screens/note_detail_pane.dart';
import 'package:wl11_note/services/markdown_export_service.dart';
import 'package:wl11_note/services/note_service.dart';

class TestNotesProvider extends NotesProvider {
  TestNotesProvider({required super.noteService});

  String? lastSavedNoteId;
  String? lastSavedContent;

  @override
  Future<Note> updateNoteContent(String noteId, String content) async {
    lastSavedNoteId = noteId;
    lastSavedContent = content;

    final note = selectedNote;
    if (note == null || note.id != noteId) {
      throw StateError('Note not found: $noteId');
    }

    return note.copyWith(content: content, updatedAt: DateTime.now());
  }
}

void main() {
  testWidgets('Markdown formatting works in the note editor', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    late Directory tempDir;
    late AppDatabase database;
    late NotesDao notesDao;
    late NotesProvider provider;

    const noteId = 'widget-test-note';
    final now = DateTime.now();

    final note = Note(
      id: noteId,
      content: 'Hello world',
      createdAt: now,
      updatedAt: now,
    );

    await tester.runAsync(() async {
      tempDir = await Directory.systemTemp.createTemp('wl11_note_editor_test_');

      database = AppDatabase(databasePath: p.join(tempDir.path, 'test.db'));

      notesDao = NotesDao(appDatabase: database);

      final noteService = NoteService(
        notesDao: notesDao,
        tagsDao: TagsDao(appDatabase: database),
      );

      provider = NotesProvider(noteService: noteService);

      await notesDao.insert(note);
      await provider.initialize();
      provider.selectNote(noteId);
    });

    final paneKey = GlobalKey<NoteDetailPaneState>();

    try {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: MaterialApp(home: NoteDetailPane(key: paneKey)),
        ),
      );

      await tester.pump();

      final editorFinder = find.byType(TextField);
      expect(editorFinder, findsOneWidget);

      final controller = tester.widget<TextField>(editorFinder).controller!;

      // Select "Hello".
      controller.selection = const TextSelection(
        baseOffset: 0,
        extentOffset: 5,
      );

      // The formatting toolbar is initially hidden.
      expect(find.byTooltip('Bold (Ctrl+B)'), findsNothing);

      // Open the popup.
      await tester.tap(find.byTooltip('Text formatting'));
      await tester.pump();

      expect(find.byTooltip('Bold (Ctrl+B)'), findsOneWidget);

      // Apply bold formatting.
      await tester.tap(find.byTooltip('Bold (Ctrl+B)'));
      await tester.pump();

      // The popup should close after formatting.
      expect(find.byTooltip('Bold (Ctrl+B)'), findsNothing);

      expect(controller.text, '**Hello** world');
      expect(
        controller.selection,
        const TextSelection(baseOffset: 2, extentOffset: 7),
      );

      // Keyboard shortcut: italic selected text.
      await tester.tap(editorFinder);
      controller.selection = const TextSelection(
        baseOffset: 10,
        extentOffset: 15,
      );

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyI);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyI);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      expect(controller.text, '**Hello** *world*');

      // Multi-line formatting: bulleted list.
      const multilineText = 'first\nsecond\nthird';

      controller.value = const TextEditingValue(
        text: multilineText,
        selection: TextSelection(
          baseOffset: 0,
          extentOffset: multilineText.length,
        ),
      );

      await tester.tap(find.byTooltip('Text formatting'));
      await tester.pump();

      await tester.tap(find.byTooltip('Bulleted list (Ctrl+Shift+8)'));
      await tester.pump();

      expect(controller.text, '- first\n- second\n- third');

      // Multi-line formatting: numbered list.
      controller.value = const TextEditingValue(
        text: multilineText,
        selection: TextSelection(
          baseOffset: 0,
          extentOffset: multilineText.length,
        ),
      );

      await tester.tap(find.byTooltip('Text formatting'));
      await tester.pump();

      await tester.tap(find.byTooltip('Numbered list (Ctrl+Shift+7)'));
      await tester.pump();

      expect(controller.text, '1. first\n2. second\n3. third');

      // Multi-line formatting: blockquote.
      controller.value = const TextEditingValue(
        text: multilineText,
        selection: TextSelection(
          baseOffset: 0,
          extentOffset: multilineText.length,
        ),
      );

      await tester.tap(find.byTooltip('Text formatting'));
      await tester.pump();

      await tester.tap(find.byTooltip('Blockquote'));
      await tester.pump();

      expect(controller.text, '> first\n> second\n> third');

      // Restore the content used by the persistence assertion.
      controller.value = const TextEditingValue(
        text: '**Hello** *world*',
        selection: TextSelection.collapsed(offset: 17),
      );

      // Preview mode hides the formatting toolbar.
      await tester.tap(find.text('Preview'));
      await tester.pump();

      expect(find.byTooltip('Bold (Ctrl+B)'), findsNothing);

      final previewFinder = find.byType(MarkdownBody);
      expect(previewFinder, findsOneWidget);

      final preview = tester.widget<MarkdownBody>(previewFinder);
      expect(preview.data, '**Hello** *world*');

      // Explicitly save and verify persistence.
      final saveResult = await tester.runAsync(
        () => paneKey.currentState!.savePendingChanges(),
      );

      expect(saveResult, isTrue);

      final savedNote = await tester.runAsync(() => notesDao.getById(noteId));

      expect(savedNote, isNotNull);
      expect(savedNote!.content, '**Hello** *world*');
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());

      provider.dispose();

      await tester.runAsync(() async {
        await database.close();
        await tempDir.delete(recursive: true);
      });
    }
  });

  testWidgets('Markdown export saves pending changes and handles results', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    late Directory tempDir;
    late AppDatabase database;
    late TestNotesProvider provider;

    const noteId = 'export-test-note';
    final now = DateTime.now();

    final note = Note(
      id: noteId,
      content: 'Original content',
      createdAt: now,
      updatedAt: now,
    );

    await tester.runAsync(() async {
      tempDir = await Directory.systemTemp.createTemp('wl11_note_export_test_');

      database = AppDatabase(databasePath: p.join(tempDir.path, 'test.db'));

      final noteService = NoteService(
        notesDao: NotesDao(appDatabase: database),
        tagsDao: TagsDao(appDatabase: database),
      );

      provider = TestNotesProvider(noteService: noteService);

      await NotesDao(appDatabase: database).insert(note);
      await provider.initialize();
      provider.selectNote(noteId);
    });

    String? exportedFileName;
    Uint8List? exportedBytes;
    String? exportResult = '/tmp/exported.md';
    Object? exportError;

    final exportService = MarkdownExportService(
      saveFile: ({required String fileName, required Uint8List bytes}) async {
        exportedFileName = fileName;
        exportedBytes = bytes;

        if (exportError != null) {
          throw exportError;
        }

        return exportResult;
      },
    );

    try {
      await tester.pumpWidget(
        ChangeNotifierProvider<NotesProvider>.value(
          value: provider,
          child: MaterialApp(
            home: NoteDetailPane(markdownExportService: exportService),
          ),
        ),
      );

      await tester.pump();

      final exportTooltip = find.byTooltip('Export as Markdown');
      final exportButton = find.ancestor(
        of: exportTooltip,
        matching: find.byType(IconButton),
      );

      expect(exportTooltip, findsOneWidget);
      expect(tester.widget<IconButton>(exportButton).onPressed, isNotNull);

      // Enter new content without waiting for the autosave timer.
      const updatedContent = '# Updated note\n\nJapanese: 日本語';

      await tester.enterText(find.byType(TextField), updatedContent);

      // Export.
      await tester.tap(exportTooltip);
      await tester.pump();
      await tester.pump();

      expect(provider.lastSavedNoteId, noteId);
      expect(provider.lastSavedContent, updatedContent);
      expect(exportedFileName, 'Updated note.md');
      expect(utf8.decode(exportedBytes!), updatedContent);
      expect(find.text('Note exported successfully.'), findsOneWidget);

      // Dismiss the success message before testing cancellation.
      tester
          .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
          .hideCurrentSnackBar();

      await tester.pumpAndSettle();

      exportResult = null;

      await tester.tap(exportTooltip);
      await tester.pump();
      await tester.pump();

      expect(find.text('Note exported successfully.'), findsNothing);

      // Export errors should be reported.
      await tester.pump(const Duration(seconds: 5));

      exportResult = '/tmp/exported.md';
      exportError = Exception('Test export error');

      await tester.tap(exportTooltip);
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('Could not export note:'), findsOneWidget);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());

      provider.dispose();

      await tester.runAsync(() async {
        await database.close();
        await tempDir.delete(recursive: true);
      });
    }
  });
}
