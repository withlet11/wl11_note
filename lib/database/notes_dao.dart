// Copyright 2026 WITHLET11 <withlet11@gmail.com>
// SPDX-License-Identifier: MIT

import 'package:sqflite/sqflite.dart';

import '../models/note.dart';
import 'app_database.dart';

class NotesDao {
  NotesDao({AppDatabase? appDatabase})
    : _appDatabase = appDatabase ?? AppDatabase.instance;

  final AppDatabase _appDatabase;

  Future<Database> get _database => _appDatabase.database;

  Future<void> insert(Note note) async {
    final db = await _database;

    await db.insert(
      'notes',
      note.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<Note?> getById(String id) async {
    final db = await _database;

    final results = await db.query(
      'notes',
      where: 'id = ? AND deleted_at_ms IS NULL',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) {
      return null;
    }

    return Note.fromMap(results.first);
  }

  Future<Note?> getByIdIncludingDeleted(String id) async {
    final db = await _database;

    final results = await db.query(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) {
      return null;
    }

    return Note.fromMap(results.first);
  }

  Future<List<Note>> getAllActive() async {
    final db = await _database;

    final results = await db.query(
      'notes',
      where: 'deleted_at_ms IS NULL',
      orderBy: 'updated_at_ms DESC',
    );

    return results.map(Note.fromMap).toList();
  }

  Future<List<Note>> getAllDeleted() async {
    final db = await _database;

    final results = await db.query(
      'notes',
      where: 'deleted_at_ms IS NOT NULL',
      orderBy: 'deleted_at_ms DESC',
    );

    return results.map(Note.fromMap).toList();
  }

  Future<int> updateContent(String id, String content) async {
    final db = await _database;

    return db.update(
      'notes',
      {
        'content': content,
        'updated_at_ms': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ? AND deleted_at_ms IS NULL',
      whereArgs: [id],
    );
  }

  Future<int> softDelete(String id) async {
    final db = await _database;

    return db.update(
      'notes',
      {'deleted_at_ms': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ? AND deleted_at_ms IS NULL',
      whereArgs: [id],
    );
  }

  Future<int> restore(String id) async {
    final db = await _database;

    return db.update(
      'notes',
      {
        'deleted_at_ms': null,
        'updated_at_ms': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ? AND deleted_at_ms IS NOT NULL',
      whereArgs: [id],
    );
  }

  Future<int> permanentlyDelete(String id) async {
    final db = await _database;

    return db.delete(
      'notes',
      where: 'id = ? AND deleted_at_ms IS NOT NULL',
      whereArgs: [id],
    );
  }

  Future<int> permanentlyDeleteAll() async {
    final db = await _database;

    return db.delete('notes', where: 'deleted_at_ms IS NOT NULL');
  }
}
