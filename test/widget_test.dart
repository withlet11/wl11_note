// Copyright 2026 WITHLET11 <withlet11@gmail.com>
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import 'package:wl11_note/database/app_database.dart';
import 'package:wl11_note/database/notes_dao.dart';
import 'package:wl11_note/database/tags_dao.dart';
import 'package:wl11_note/main.dart';
import 'package:wl11_note/providers/notes_provider.dart';
import 'package:wl11_note/services/note_service.dart';

void main() {
  testWidgets('Application initializes successfully', (tester) async {
    late Directory tempDir;
    late AppDatabase database;
    late NotesProvider provider;

    await tester.runAsync(() async {
      tempDir = await Directory.systemTemp.createTemp('wl11_note_widget_test_');

      database = AppDatabase(databasePath: p.join(tempDir.path, 'test.db'));

      final noteService = NoteService(
        notesDao: NotesDao(appDatabase: database),
        tagsDao: TagsDao(appDatabase: database),
      );

      provider = NotesProvider(noteService: noteService);

      await provider.initialize();
    });

    try {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const Wl11NoteApp(),
        ),
      );

      await tester.pump();

      expect(find.text('wl11_note'), findsOneWidget);
      expect(find.text('Initialization successful'), findsOneWidget);
      expect(find.text('Active notes: 0'), findsOneWidget);
      expect(find.text('Deleted notes: 0'), findsOneWidget);
      expect(find.text('Tags: 0'), findsOneWidget);
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
