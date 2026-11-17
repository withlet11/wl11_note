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
  late AppDatabase appDatabase;
  late NotesProvider provider;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wl11_note_provider_test_');

    appDatabase = AppDatabase(databasePath: p.join(tempDir.path, 'test.db'));

    final noteService = NoteService(
      notesDao: NotesDao(appDatabase: appDatabase),
      tagsDao: TagsDao(appDatabase: appDatabase),
    );

    provider = NotesProvider(noteService: noteService);
  });

  tearDown(() async {
    provider.dispose();
    await appDatabase.close();
    await tempDir.delete(recursive: true);
  });

  group('Initialization', () {
    test('loads initial data', () async {
      await provider.initialize();

      expect(provider.activeNotes, isEmpty);
      expect(provider.deletedNotes, isEmpty);
      expect(provider.tags, isEmpty);
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
    });

    test('refreshes data from the database', () async {
      await provider.createNote(content: 'Test note');
      await provider.createTag('Work');

      // Create data outside the provider to verify refresh.
      final externalService = NoteService(
        notesDao: NotesDao(appDatabase: appDatabase),
        tagsDao: TagsDao(appDatabase: appDatabase),
      );

      await externalService.createNote(content: 'External note');
      await externalService.createTag('Personal');

      await provider.refresh();

      expect(provider.activeNotes, hasLength(2));
      expect(provider.tags, hasLength(2));
    });
  });

  group('Selection', () {
    test('selects an active note', () async {
      final note = await provider.createNote();

      expect(provider.selectedNoteId, note.id);
      expect(provider.selectedNote?.id, note.id);

      provider.clearSelection();

      expect(provider.selectedNoteId, isNull);
      expect(provider.selectedNote, isNull);
    });

    test('rejects selection of a nonexistent note', () async {
      await provider.initialize();

      expect(provider.selectNote('missing-note'), isFalse);
      expect(provider.selectedNoteId, isNull);
    });

    test('clears selection when the selected note is deleted', () async {
      final note = await provider.createNote();

      await provider.deleteNote(note.id);

      expect(provider.selectedNoteId, isNull);
      expect(provider.selectedNote, isNull);
    });
  });

  group('Notes', () {
    test('creates and selects a note', () async {
      final note = await provider.createNote(content: '# New note');

      expect(provider.activeNotes, hasLength(1));
      expect(provider.activeNotes.first.id, note.id);
      expect(provider.selectedNote, isNotNull);
      expect(provider.selectedNote!.content, '# New note');
    });

    test('updates note content and provider state', () async {
      final note = await provider.createNote();

      await provider.updateNoteContent(note.id, 'Updated content');

      expect(provider.activeNotes.first.content, 'Updated content');
      expect(provider.selectedNote!.content, 'Updated content');
    });

    test('moves a deleted note to the deleted list', () async {
      final note = await provider.createNote();

      expect(await provider.deleteNote(note.id), isTrue);

      expect(provider.activeNotes, isEmpty);
      expect(provider.deletedNotes, hasLength(1));
      expect(provider.deletedNotes.first.id, note.id);
    });

    test('restores a deleted note', () async {
      final note = await provider.createNote();

      await provider.deleteNote(note.id);

      expect(await provider.restoreNote(note.id), isTrue);

      expect(provider.activeNotes, hasLength(1));
      expect(provider.activeNotes.first.id, note.id);
      expect(provider.deletedNotes, isEmpty);
    });

    test('returns false when deleting or restoring a missing note', () async {
      expect(await provider.deleteNote('missing-note'), isFalse);
      expect(await provider.restoreNote('missing-note'), isFalse);
    });
  });

  group('Tags', () {
    test('creates and maintains tags', () async {
      final tag = await provider.createTag('Work');

      expect(provider.tags, hasLength(1));
      expect(provider.tags.first.id, tag.id);
      expect(provider.tags.first.name, 'Work');
    });

    test('renames a tag', () async {
      final tag = await provider.createTag('Work');

      expect(await provider.renameTag(tag.id, 'Projects'), isTrue);

      expect(provider.tags.first.name, 'Projects');
    });

    test('deletes a tag', () async {
      final tag = await provider.createTag('Work');

      expect(await provider.deleteTag(tag.id), isTrue);
      expect(provider.tags, isEmpty);
    });

    test('assigns and removes a tag', () async {
      final note = await provider.createNote();
      final tag = await provider.createTag('Work');

      expect(await provider.assignTag(note.id, tag.id), isTrue);

      var noteTags = await provider.getTagsForNote(note.id);

      expect(noteTags, hasLength(1));
      expect(noteTags.first.id, tag.id);

      expect(await provider.removeTag(note.id, tag.id), isTrue);

      noteTags = await provider.getTagsForNote(note.id);

      expect(noteTags, isEmpty);
    });

    test('returns notes associated with a tag', () async {
      final note = await provider.createNote();
      final tag = await provider.createTag('Work');

      await provider.assignTag(note.id, tag.id);

      final notes = await provider.getNotesForTag(tag.id);

      expect(notes, hasLength(1));
      expect(notes.first.id, note.id);
    });
  });

  group('Error handling', () {
    test('stores an error when an operation fails', () async {
      await expectLater(
        provider.updateNoteContent('missing-note', 'Content'),
        throwsStateError,
      );

      expect(provider.hasError, isTrue);
      expect(provider.error, isA<StateError>());
      expect(provider.isLoading, isFalse);
    });

    test('clears a stored error', () async {
      await expectLater(
        provider.updateNoteContent('missing-note', 'Content'),
        throwsStateError,
      );

      provider.clearError();

      expect(provider.hasError, isFalse);
      expect(provider.error, isNull);
    });
  });
}
