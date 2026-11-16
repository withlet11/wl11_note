// Copyright 2026 WITHLET11 <withlet11@gmail.com>
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:wl11_note/database/app_database.dart';
import 'package:wl11_note/database/notes_dao.dart';
import 'package:wl11_note/database/tags_dao.dart';
import 'package:wl11_note/models/note.dart';

void main() {
  late Directory tempDir;
  late AppDatabase appDatabase;
  late NotesDao notesDao;
  late TagsDao tagsDao;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wl11_note_test_');

    appDatabase = AppDatabase(databasePath: p.join(tempDir.path, 'test.db'));

    notesDao = NotesDao(appDatabase: appDatabase);
    tagsDao = TagsDao(appDatabase: appDatabase);
  });

  tearDown(() async {
    await appDatabase.close();
    await tempDir.delete(recursive: true);
  });

  Future<Note> createTestNote({String id = 'test-note-1'}) async {
    final oldTime = DateTime.now().subtract(const Duration(days: 1));

    final note = Note(
      id: id,
      content: '# Test note',
      createdAt: oldTime,
      updatedAt: oldTime,
    );

    await notesDao.insert(note);

    return note;
  }

  test('create tag and prevent case-insensitive duplicates', () async {
    final first = await tagsDao.createTag('  Work  ');
    final second = await tagsDao.createTag('work');

    expect(first.id, second.id);
    expect(first.name, 'Work');
    expect(await tagsDao.getAll(), hasLength(1));
  });

  test('reject empty tag names', () async {
    expect(() => tagsDao.createTag('   '), throwsArgumentError);
  });

  test('rename tag and update associated notes', () async {
    final note = await createTestNote();
    final tag = await tagsDao.createTag('Work');

    await tagsDao.assignTag(note.id, tag.id);

    final result = await tagsDao.renameTag(tag.id, 'Projects');

    expect(result, 1);

    final renamed = await tagsDao.getById(tag.id);

    expect(renamed!.name, 'Projects');

    final updatedNote = await notesDao.getById(note.id);

    expect(updatedNote!.updatedAt.isAfter(note.updatedAt), isTrue);
  });

  test('reject renaming to an existing tag name', () async {
    final first = await tagsDao.createTag('Work');
    final second = await tagsDao.createTag('Personal');

    expect(() => tagsDao.renameTag(second.id, 'work'), throwsArgumentError);

    expect((await tagsDao.getById(first.id))!.name, 'Work');
    expect((await tagsDao.getById(second.id))!.name, 'Personal');
  });

  test('assign and remove tag relationships', () async {
    final note = await createTestNote();
    final tag = await tagsDao.createTag('Work');

    expect(await tagsDao.assignTag(note.id, tag.id), isTrue);

    expect(await tagsDao.assignTag(note.id, tag.id), isFalse);

    expect(await tagsDao.getTagsForNote(note.id), hasLength(1));

    expect(await tagsDao.getNotesForTag(tag.id), hasLength(1));

    expect(await tagsDao.removeTag(note.id, tag.id), isTrue);

    expect(await tagsDao.removeTag(note.id, tag.id), isFalse);

    expect(await tagsDao.getTagsForNote(note.id), isEmpty);
  });

  test('tag changes update note modification timestamp', () async {
    final note = await createTestNote();
    final tag = await tagsDao.createTag('Work');

    await tagsDao.assignTag(note.id, tag.id);

    final assigned = await notesDao.getById(note.id);

    expect(assigned!.updatedAt.isAfter(note.updatedAt), isTrue);

    await tagsDao.removeTag(note.id, tag.id);

    final removed = await notesDao.getById(note.id);

    expect(removed!.updatedAt.isAfter(assigned.updatedAt), isTrue);
  });

  test('deleting tag removes its relationships', () async {
    final note = await createTestNote();
    final tag = await tagsDao.createTag('Work');

    await tagsDao.assignTag(note.id, tag.id);

    final result = await tagsDao.deleteTag(tag.id);

    expect(result, 1);
    expect(await tagsDao.getById(tag.id), isNull);
    expect(await tagsDao.getTagsForNote(note.id), isEmpty);
    expect(await tagsDao.getNotesForTag(tag.id), isEmpty);
  });

  test('soft-deleted note retains tag relationships', () async {
    final note = await createTestNote();
    final tag = await tagsDao.createTag('Work');

    await tagsDao.assignTag(note.id, tag.id);
    await notesDao.softDelete(note.id);

    expect(await tagsDao.getTagsForNote(note.id), hasLength(1));

    expect(await tagsDao.getNotesForTag(tag.id), isEmpty);
  });

  test('reject assigning a tag to a deleted note', () async {
    final note = await createTestNote();
    final tag = await tagsDao.createTag('Work');

    await notesDao.softDelete(note.id);

    expect(() => tagsDao.assignTag(note.id, tag.id), throwsStateError);
  });
}
