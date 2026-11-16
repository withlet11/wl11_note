// Copyright 2026 WITHLET11 <withlet11@gmail.com>
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;

class AppDatabase {
  AppDatabase({this.databaseName = 'wl11_note.db', String? databasePath})
    : _customDatabasePath = databasePath;

  static final AppDatabase instance = AppDatabase();

  final String databaseName;
  final String? _customDatabasePath;

  static const int _databaseVersion = 1;

  Future<Database>? _databaseFuture;

  Future<Database> get database {
    return _databaseFuture ??= _openDatabase();
  }

  Future<Database> _openDatabase() async {
    if (Platform.isLinux) {
      ffi.sqfliteFfiInit();
      databaseFactory = ffi.databaseFactoryFfi;
    }

    final databasePath =
        _customDatabasePath ?? p.join(await getDatabasesPath(), databaseName);

    await Directory(p.dirname(databasePath)).create(recursive: true);

    return openDatabase(
      databasePath,
      version: _databaseVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createSchema(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 1) {
      await _createSchema(db);
    }
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE notes (
        id TEXT PRIMARY KEY,
        content TEXT NOT NULL,
        created_at_ms INTEGER NOT NULL,
        updated_at_ms INTEGER NOT NULL,
        deleted_at_ms INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        name_key TEXT NOT NULL UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE note_tags (
        note_id TEXT NOT NULL,
        tag_id INTEGER NOT NULL,
        PRIMARY KEY (note_id, tag_id),
        FOREIGN KEY (note_id)
          REFERENCES notes (id)
          ON DELETE CASCADE,
        FOREIGN KEY (tag_id)
          REFERENCES tags (id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_notes_updated_at
      ON notes (updated_at_ms)
    ''');

    await db.execute('''
      CREATE INDEX idx_notes_deleted_at
      ON notes (deleted_at_ms)
    ''');

    await db.execute('''
      CREATE INDEX idx_note_tags_tag_id
      ON note_tags (tag_id)
    ''');
  }

  Future<void> close() async {
    final future = _databaseFuture;

    if (future == null) {
      return;
    }

    final db = await future;
    await db.close();

    _databaseFuture = null;
  }
}
