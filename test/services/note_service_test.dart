// Copyright 2026 WITHLET11 <withlet11@gmail.com>
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:wl11_note/database/app_database.dart';
import 'package:wl11_note/database/notes_dao.dart';
import 'package:wl11_note/database/tags_dao.dart';
import 'package:wl11_note/services/note_service.dart';

void main() {
  late Directory tempDir;
  late AppDatabase appDatabase;
  late NoteService noteService;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wl11_note_service_test_');

    appDatabase = AppDatabase(databasePath: p.join(tempDir.path, 'test.db'));

    noteService = NoteService(
      notesDao: NotesDao(appDatabase: appDatabase),
      tagsDao: TagsDao(appDatabase: appDatabase),
    );
  });

  tearDown(() async {
    await appDatabase.close();
    await tempDir.delete(recursive: true);
  });

  group('Notes', () {
    test('create note with default content', () async {
      final note = await noteService.createNote();

      expect(note.id, isNotEmpty);
      expect(note.content, isEmpty);
      expect(note.createdAt, note.updatedAt);
      expect(note.isDeleted, isFalse);

      final retrieved = await noteService.getNote(note.id);

      expect(retrieved, isNotNull);
      expect(retrieved!.id, note.id);
    });

    test('create notes with unique IDs', () async {
      final first = await noteService.createNote();
      final second = await noteService.createNote();

      expect(first.id, isNot(second.id));
    });

    test('create note with initial content', () async {
      final note = await noteService.createNote(content: '# My first note');

      expect(note.content, '# My first note');
    });

    test('retrieve active notes', () async {
      final first = await noteService.createNote(content: 'First note');

      final second = await noteService.createNote(content: 'Second note');

      final notes = await noteService.getAllActiveNotes();

      expect(notes, hasLength(2));
      expect(notes.map((note) => note.id), containsAll([first.id, second.id]));
    });

    test('update note content', () async {
      final note = await noteService.createNote();

      final updated = await noteService.updateNoteContent(
        note.id,
        '# Updated content',
      );

      expect(updated.id, note.id);
      expect(updated.content, '# Updated content');

      final retrieved = await noteService.getNote(note.id);

      expect(retrieved!.content, '# Updated content');
    });

    test('cannot update a nonexistent note', () async {
      expect(
        () => noteService.updateNoteContent('missing-note', 'Content'),
        throwsStateError,
      );
    });

    test('soft-delete and restore note', () async {
      final note = await noteService.createNote();

      expect(await noteService.deleteNote(note.id), isTrue);
      expect(await noteService.getNote(note.id), isNull);

      final deletedNotes = await noteService.getAllDeletedNotes();

      expect(deletedNotes, hasLength(1));
      expect(deletedNotes.first.id, note.id);

      expect(await noteService.restoreNote(note.id), isTrue);

      final restored = await noteService.getNote(note.id);

      expect(restored, isNotNull);
      expect(restored!.isDeleted, isFalse);
    });

    test('deleting or restoring nonexistent note returns false', () async {
      expect(await noteService.deleteNote('missing-note'), isFalse);

      expect(await noteService.restoreNote('missing-note'), isFalse);
    });
  });

  group('Tags', () {
    test('create and retrieve tag', () async {
      final tag = await noteService.createTag('Work');

      expect(tag.name, 'Work');

      final tags = await noteService.getAllTags();

      expect(tags, hasLength(1));
      expect(tags.first.id, tag.id);
    });

    test('retrieve tags associated with a note', () async {
      final note = await noteService.createNote();
      final tag = await noteService.createTag('Work');

      await noteService.assignTag(note.id, tag.id);

      final tags = await noteService.getTagsForNote(note.id);

      expect(tags, hasLength(1));
      expect(tags.first.id, tag.id);
    });

    test('retrieve notes associated with a tag', () async {
      final note = await noteService.createNote();
      final tag = await noteService.createTag('Work');

      await noteService.assignTag(note.id, tag.id);

      final notes = await noteService.getNotesForTag(tag.id);

      expect(notes, hasLength(1));
      expect(notes.first.id, note.id);
    });

    test('rename tag', () async {
      final tag = await noteService.createTag('Work');

      expect(await noteService.renameTag(tag.id, 'Projects'), isTrue);

      final tags = await noteService.getAllTags();

      expect(tags.first.name, 'Projects');
    });

    test('delete tag', () async {
      final note = await noteService.createNote();
      final tag = await noteService.createTag('Work');

      await noteService.assignTag(note.id, tag.id);

      expect(await noteService.deleteTag(tag.id), isTrue);

      expect(await noteService.getAllTags(), isEmpty);
      expect(await noteService.getTagsForNote(note.id), isEmpty);
    });

    test('rename or delete nonexistent tag returns false', () async {
      expect(await noteService.renameTag(999, 'Projects'), isFalse);

      expect(await noteService.deleteTag(999), isFalse);
    });

    test('assign and remove tag', () async {
      final note = await noteService.createNote();
      final tag = await noteService.createTag('Work');

      expect(await noteService.assignTag(note.id, tag.id), isTrue);

      expect(await noteService.assignTag(note.id, tag.id), isFalse);

      expect(await noteService.removeTag(note.id, tag.id), isTrue);

      expect(await noteService.removeTag(note.id, tag.id), isFalse);
    });
  });
}
