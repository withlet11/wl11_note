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
  testWidgets('Main screen displays the empty notes state', (tester) async {
    // Set a desktop-sized viewport.
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
      expect(find.text('No notes yet'), findsOneWidget);
      expect(find.text('Create a note to get started.'), findsOneWidget);
      expect(find.text('Select a note or create a new one.'), findsOneWidget);
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
