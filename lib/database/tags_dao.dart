// Copyright 2026 WITHLET11 <withlet11@gmail.com>
// SPDX-License-Identifier: MIT

import 'package:sqflite/sqflite.dart';

import '../models/note.dart';
import '../models/tag.dart';
import 'app_database.dart';

class TagsDao {
  TagsDao({AppDatabase? appDatabase})
    : _appDatabase = appDatabase ?? AppDatabase.instance;

  final AppDatabase _appDatabase;

  Future<Database> get _database => _appDatabase.database;

  String _normalizeName(String name) {
    return name.trim().toLowerCase();
  }

  Future<Tag> createTag(String name) async {
    final trimmedName = name.trim();
    final nameKey = _normalizeName(name);

    if (nameKey.isEmpty) {
      throw ArgumentError('Tag name cannot be empty.');
    }

    final db = await _database;

    return db.transaction((txn) async {
      final existing = await txn.query(
        'tags',
        where: 'name_key = ?',
        whereArgs: [nameKey],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        return Tag.fromMap(existing.first);
      }

      final id = await txn.insert('tags', {
        'name': trimmedName,
        'name_key': nameKey,
      });

      return Tag(id: id, name: trimmedName);
    });
  }

  Future<Tag?> getById(int id) async {
    final db = await _database;

    final results = await db.query(
      'tags',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) {
      return null;
    }

    return Tag.fromMap(results.first);
  }

  Future<List<Tag>> getAll() async {
    final db = await _database;

    final results = await db.query(
      'tags',
      orderBy: 'name_key COLLATE NOCASE ASC',
    );

    return results.map(Tag.fromMap).toList();
  }

  Future<int> renameTag(int id, String newName) async {
    final trimmedName = newName.trim();
    final nameKey = _normalizeName(newName);

    if (nameKey.isEmpty) {
      throw ArgumentError('Tag name cannot be empty.');
    }

    final db = await _database;

    return db.transaction((txn) async {
      final existing = await txn.query(
        'tags',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (existing.isEmpty) {
        return 0;
      }

      if (existing.first['name_key'] == nameKey) {
        if (existing.first['name'] == trimmedName) {
          return 0;
        }
      } else {
        final duplicate = await txn.query(
          'tags',
          where: 'name_key = ? AND id != ?',
          whereArgs: [nameKey, id],
          limit: 1,
        );

        if (duplicate.isNotEmpty) {
          throw ArgumentError('A tag with this name already exists.');
        }
      }

      final now = DateTime.now().millisecondsSinceEpoch;

      final updated = await txn.update(
        'tags',
        {'name': trimmedName, 'name_key': nameKey},
        where: 'id = ?',
        whereArgs: [id],
      );

      await txn.rawUpdate(
        '''
        UPDATE notes
        SET updated_at_ms = ?
        WHERE id IN (
          SELECT note_id
          FROM note_tags
          WHERE tag_id = ?
        )
        AND deleted_at_ms IS NULL
        ''',
        [now, id],
      );

      return updated;
    });
  }

  Future<int> deleteTag(int id) async {
    final db = await _database;

    return db.transaction((txn) async {
      final now = DateTime.now().millisecondsSinceEpoch;

      await txn.rawUpdate(
        '''
        UPDATE notes
        SET updated_at_ms = ?
        WHERE id IN (
          SELECT note_id
          FROM note_tags
          WHERE tag_id = ?
        )
        AND deleted_at_ms IS NULL
        ''',
        [now, id],
      );

      return txn.delete('tags', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<bool> assignTag(String noteId, int tagId) async {
    final db = await _database;

    return db.transaction((txn) async {
      final note = await txn.query(
        'notes',
        columns: ['id'],
        where: 'id = ? AND deleted_at_ms IS NULL',
        whereArgs: [noteId],
      );

      if (note.isEmpty) {
        throw StateError('Note does not exist or is deleted.');
      }

      final tag = await txn.query(
        'tags',
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [tagId],
      );

      if (tag.isEmpty) {
        throw StateError('Tag does not exist.');
      }

      final existing = await txn.query(
        'note_tags',
        columns: ['note_id'],
        where: 'note_id = ? AND tag_id = ?',
        whereArgs: [noteId, tagId],
      );

      if (existing.isNotEmpty) {
        return false;
      }

      await txn.insert('note_tags', {'note_id': noteId, 'tag_id': tagId});

      await txn.update(
        'notes',
        {'updated_at_ms': DateTime.now().millisecondsSinceEpoch},
        where: 'id = ?',
        whereArgs: [noteId],
      );

      return true;
    });
  }

  Future<bool> removeTag(String noteId, int tagId) async {
    final db = await _database;

    return db.transaction((txn) async {
      final deleted = await txn.delete(
        'note_tags',
        where: 'note_id = ? AND tag_id = ?',
        whereArgs: [noteId, tagId],
      );

      if (deleted == 0) {
        return false;
      }

      await txn.update(
        'notes',
        {'updated_at_ms': DateTime.now().millisecondsSinceEpoch},
        where: 'id = ? AND deleted_at_ms IS NULL',
        whereArgs: [noteId],
      );

      return true;
    });
  }

  Future<List<Tag>> getTagsForNote(String noteId) async {
    final db = await _database;

    final results = await db.rawQuery(
      '''
      SELECT tags.*
      FROM tags
      INNER JOIN note_tags
        ON tags.id = note_tags.tag_id
      WHERE note_tags.note_id = ?
      ORDER BY tags.name_key COLLATE NOCASE ASC
      ''',
      [noteId],
    );

    return results.map(Tag.fromMap).toList();
  }

  Future<List<Note>> getNotesForTag(int tagId) async {
    final db = await _database;

    final results = await db.rawQuery(
      '''
      SELECT notes.*
      FROM notes
      INNER JOIN note_tags
        ON notes.id = note_tags.note_id
      WHERE note_tags.tag_id = ?
        AND notes.deleted_at_ms IS NULL
      ORDER BY notes.updated_at_ms DESC
      ''',
      [tagId],
    );

    return results.map(Note.fromMap).toList();
  }
}
