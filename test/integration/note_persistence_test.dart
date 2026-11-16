// Copyright 2026 WITHLET11 <withlet11@gmail.com>
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:wl11_note/database/app_database.dart';
import 'package:wl11_note/database/notes_dao.dart';
import 'package:wl11_note/database/tags_dao.dart';
import 'package:wl11_note/providers/notes_provider.dart';
import 'package:wl11_note/services/note_service.dart';

void main() {
  late Directory tempDir;
  late String databasePath;

  AppDatabase? firstDatabase;
  AppDatabase? reopenedDatabase;
  NotesProvider? firstProvider;
  NotesProvider? secondProvider;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'wl11_note_persistence_test_',
    );
    databasePath = p.join(tempDir.path, 'test.db');
  });

  tearDown(() async {
    firstProvider?.dispose();
    secondProvider?.dispose();

    await firstDatabase?.close();
    await reopenedDatabase?.close();

    await tempDir.delete(recursive: true);
  });

  test('notes, tags, and deletion state persist across restarts', () async {
    // First application session.
    firstDatabase = AppDatabase(databasePath: databasePath);

    final firstService = NoteService(
      notesDao: NotesDao(appDatabase: firstDatabase),
      tagsDao: TagsDao(appDatabase: firstDatabase),
    );

    firstProvider = NotesProvider(noteService: firstService);

    await firstProvider!.initialize();

    final createdNote = await firstProvider!.createNote(
      content: '# Persistence test\n\nThis note must survive a restart.',
    );

    final createdTag = await firstProvider!.createTag('Important');

    await firstProvider!.assignTag(createdNote.id, createdTag.id);

    // Close the first application session.
    firstProvider!.dispose();
    firstProvider = null;

    await firstDatabase!.close();
    firstDatabase = null;

    // Second application session.
    reopenedDatabase = AppDatabase(databasePath: databasePath);

    final reopenedService = NoteService(
      notesDao: NotesDao(appDatabase: reopenedDatabase),
      tagsDao: TagsDao(appDatabase: reopenedDatabase),
    );

    secondProvider = NotesProvider(noteService: reopenedService);

    await secondProvider!.initialize();

    // Verify note and tag persistence.
    expect(secondProvider!.activeNotes, hasLength(1));
    expect(secondProvider!.activeNotes.single.id, createdNote.id);
    expect(secondProvider!.activeNotes.single.content, createdNote.content);

    final restoredTags = await secondProvider!.getTagsForNote(createdNote.id);

    expect(restoredTags, hasLength(1));
    expect(restoredTags.single.id, createdTag.id);
    expect(restoredTags.single.name, 'Important');

    // Soft-delete the note.
    await secondProvider!.deleteNote(createdNote.id);

    expect(secondProvider!.activeNotes, isEmpty);
    expect(secondProvider!.deletedNotes, hasLength(1));

    // Close the second application session.
    secondProvider!.dispose();
    secondProvider = null;

    await reopenedDatabase!.close();
    reopenedDatabase = null;

    // Third application session.
    final thirdDatabase = AppDatabase(databasePath: databasePath);

    final thirdService = NoteService(
      notesDao: NotesDao(appDatabase: thirdDatabase),
      tagsDao: TagsDao(appDatabase: thirdDatabase),
    );

    final thirdProvider = NotesProvider(noteService: thirdService);

    try {
      await thirdProvider.initialize();

      // Verify that deletion persisted.
      expect(thirdProvider.activeNotes, isEmpty);
      expect(thirdProvider.deletedNotes, hasLength(1));
      expect(thirdProvider.deletedNotes.single.id, createdNote.id);

      // Restore the note.
      await thirdProvider.restoreNote(createdNote.id);

      expect(thirdProvider.activeNotes, hasLength(1));
      expect(thirdProvider.deletedNotes, isEmpty);
    } finally {
      thirdProvider.dispose();
      await thirdDatabase.close();
    }

    // Fourth application session: verify restoration persisted.
    final fourthDatabase = AppDatabase(databasePath: databasePath);

    final fourthService = NoteService(
      notesDao: NotesDao(appDatabase: fourthDatabase),
      tagsDao: TagsDao(appDatabase: fourthDatabase),
    );

    final fourthProvider = NotesProvider(noteService: fourthService);

    try {
      await fourthProvider.initialize();

      expect(fourthProvider.activeNotes, hasLength(1));
      expect(fourthProvider.deletedNotes, isEmpty);
      expect(fourthProvider.activeNotes.single.id, createdNote.id);

      final finalTags = await fourthProvider.getTagsForNote(createdNote.id);

      expect(finalTags, hasLength(1));
      expect(finalTags.single.name, 'Important');
    } finally {
      fourthProvider.dispose();
      await fourthDatabase.close();
    }
  });
}
