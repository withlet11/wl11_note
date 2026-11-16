// Copyright 2026 WITHLET11 <withlet11@gmail.com>
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:wl11_note/database/app_database.dart';
import 'package:wl11_note/database/notes_dao.dart';
import 'package:wl11_note/models/note.dart';

void main() {
  late Directory tempDir;
  late AppDatabase appDatabase;
  late NotesDao notesDao;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wl11_note_test_');

    appDatabase = AppDatabase(databasePath: p.join(tempDir.path, 'test.db'));

    notesDao = NotesDao(appDatabase: appDatabase);
  });

  tearDown(() async {
    await appDatabase.close();
    await tempDir.delete(recursive: true);
  });

  Note createTestNote({
    String id = 'test-note-1',
    String content = '# Test note',
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();

    return Note(
      id: id,
      content: content,
      createdAt: now,
      updatedAt: updatedAt ?? now,
    );
  }

  test('insert and retrieve a note', () async {
    final note = createTestNote();

    await notesDao.insert(note);

    final retrieved = await notesDao.getById(note.id);

    expect(retrieved, isNotNull);
    expect(retrieved!.id, note.id);
    expect(retrieved.content, note.content);
  });

  test('update note content and timestamp', () async {
    final oldTime = DateTime.now().subtract(const Duration(days: 1));

    final note = createTestNote(updatedAt: oldTime);

    await notesDao.insert(note);

    final result = await notesDao.updateContent(note.id, '# Updated note');

    expect(result, 1);

    final updated = await notesDao.getById(note.id);

    expect(updated!.content, '# Updated note');
    expect(updated.updatedAt.isAfter(oldTime), isTrue);
  });

  test('soft-delete hides a note but preserves it', () async {
    final note = createTestNote();

    await notesDao.insert(note);

    final result = await notesDao.softDelete(note.id);

    expect(result, 1);
    expect(await notesDao.getById(note.id), isNull);

    final deleted = await notesDao.getByIdIncludingDeleted(note.id);

    expect(deleted, isNotNull);
    expect(deleted!.isDeleted, isTrue);
    expect(await notesDao.getAllActive(), isEmpty);
    expect(await notesDao.getAllDeleted(), hasLength(1));
  });

  test('restore a deleted note', () async {
    final note = createTestNote();

    await notesDao.insert(note);
    await notesDao.softDelete(note.id);

    final result = await notesDao.restore(note.id);

    expect(result, 1);

    final restored = await notesDao.getById(note.id);

    expect(restored, isNotNull);
    expect(restored!.isDeleted, isFalse);
  });

  test('update and delete nonexistent notes', () async {
    expect(await notesDao.updateContent('missing', 'Content'), 0);

    expect(await notesDao.softDelete('missing'), 0);

    expect(await notesDao.restore('missing'), 0);
  });
}
