// Copyright 2026 WITHLET11 <withlet11@gmail.com>
// SPDX-License-Identifier: MIT

import 'package:uuid/uuid.dart';

import '../database/notes_dao.dart';
import '../database/tags_dao.dart';
import '../models/note.dart';
import '../models/tag.dart';

class NoteService {
  NoteService({NotesDao? notesDao, TagsDao? tagsDao})
    : _notesDao = notesDao ?? NotesDao(),
      _tagsDao = tagsDao ?? TagsDao();

  final NotesDao _notesDao;
  final TagsDao _tagsDao;

  static const _uuid = Uuid();

  // Notes

  Future<Note> createNote({String content = ''}) async {
    final now = DateTime.now();

    final note = Note(
      id: _uuid.v4(),
      content: content,
      createdAt: now,
      updatedAt: now,
    );

    await _notesDao.insert(note);

    return note;
  }

  Future<Note?> getNote(String id) {
    return _notesDao.getById(id);
  }

  Future<List<Note>> getAllActiveNotes() {
    return _notesDao.getAllActive();
  }

  Future<List<Note>> getAllDeletedNotes() {
    return _notesDao.getAllDeleted();
  }

  Future<Note> updateNoteContent(String id, String content) async {
    final updated = await _notesDao.updateContent(id, content);

    if (updated == 0) {
      throw StateError('Note does not exist or is deleted.');
    }

    final note = await _notesDao.getById(id);

    if (note == null) {
      throw StateError('Note could not be retrieved after updating.');
    }

    return note;
  }

  Future<bool> deleteNote(String id) async {
    final deleted = await _notesDao.softDelete(id);
    return deleted > 0;
  }

  Future<bool> restoreNote(String id) async {
    final restored = await _notesDao.restore(id);
    return restored > 0;
  }

  Future<bool> permanentlyDeleteNote(String id) async {
    final deleted = await _notesDao.permanentlyDelete(id);
    return deleted > 0;
  }

  Future<int> permanentlyDeleteAllNotes() {
    return _notesDao.permanentlyDeleteAll();
  }

  // Tags

  Future<List<Tag>> getAllTags() {
    return _tagsDao.getAll();
  }

  Future<List<Tag>> getTagsForNote(String noteId) {
    return _tagsDao.getTagsForNote(noteId);
  }

  Future<List<Note>> getNotesForTag(int tagId) {
    return _tagsDao.getNotesForTag(tagId);
  }

  Future<Tag> createTag(String name) {
    return _tagsDao.createTag(name);
  }

  Future<bool> renameTag(int tagId, String newName) async {
    final renamed = await _tagsDao.renameTag(tagId, newName);
    return renamed > 0;
  }

  Future<bool> deleteTag(int tagId) async {
    final deleted = await _tagsDao.deleteTag(tagId);
    return deleted > 0;
  }

  Future<bool> assignTag(String noteId, int tagId) {
    return _tagsDao.assignTag(noteId, tagId);
  }

  Future<bool> removeTag(String noteId, int tagId) {
    return _tagsDao.removeTag(noteId, tagId);
  }
}
