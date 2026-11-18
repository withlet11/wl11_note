// Copyright 2026 WITHLET11 <withlet11@gmail.com>
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

import '../models/note.dart' show Note;
import '../models/tag.dart';
import '../services/note_service.dart';
import '../utils/note_title.dart';

class NotesProvider extends ChangeNotifier {
  NotesProvider({NoteService? noteService})
    : _noteService = noteService ?? NoteService();

  final NoteService _noteService;

  List<Note> _activeNotes = [];
  List<Note> _deletedNotes = [];
  List<Tag> _tags = [];

  // Search and filtering

  String _searchQuery = '';
  final Set<int> _selectedTagIds = {};
  Map<int, Set<String>> _noteIdsByTag = {};

  Map<String, List<Tag>> _tagsByNoteId = {};

  List<Tag> tagsForNote(String noteId) {
    return List.unmodifiable(_tagsByNoteId[noteId] ?? const <Tag>[]);
  }

  String get searchQuery => _searchQuery;

  Set<int> get selectedTagIds => Set.unmodifiable(_selectedTagIds);

  bool isTagSelected(int tagId) => _selectedTagIds.contains(tagId);

  List<Note> get filteredNotes {
    final query = _searchQuery.trim().toLowerCase();

    return List.unmodifiable(
      _activeNotes.where((note) {
        final matchesQuery =
            query.isEmpty ||
            deriveNoteTitle(note.content).toLowerCase().contains(query) ||
            note.content.toLowerCase().contains(query);

        final matchesTags =
            _selectedTagIds.isEmpty ||
            _selectedTagIds.every(
              (tagId) => _noteIdsByTag[tagId]?.contains(note.id) ?? false,
            );

        return matchesQuery && matchesTags;
      }),
    );
  }

  void setSearchQuery(String query) {
    if (_searchQuery == query) return;

    _searchQuery = query;
    notifyListeners();
  }

  void toggleTagFilter(int tagId) {
    if (!_tags.any((tag) => tag.id == tagId)) return;

    if (!_selectedTagIds.add(tagId)) {
      _selectedTagIds.remove(tagId);
    }

    notifyListeners();
  }

  void clearTagFilters() {
    if (_selectedTagIds.isEmpty) return;

    _selectedTagIds.clear();
    notifyListeners();
  }

  // General state

  String? _selectedNoteId;

  int _pendingOperations = 0;

  bool get isLoading => _pendingOperations > 0;

  Object? _error;

  List<Note> get activeNotes => List.unmodifiable(_activeNotes);

  List<Note> get deletedNotes => List.unmodifiable(_deletedNotes);

  List<Tag> get tags => List.unmodifiable(_tags);

  String? get selectedNoteId => _selectedNoteId;

  Note? get selectedNote {
    final id = _selectedNoteId;
    if (id == null) return null;

    for (final note in _activeNotes) {
      if (note.id == id) return note;
    }

    return null;
  }

  Object? get error => _error;

  bool get hasError => _error != null;

  // Initialization and refresh

  Future<void> initialize() => _run(_refreshAll);

  Future<void> refresh() => _run(_refreshAll);

  Future<void> _refreshAll() async {
    await _refreshNotes();
    await _refreshTags();
    _validateSelection();
  }

  Future<void> _refreshNotes() async {
    _activeNotes = await _noteService.getAllActiveNotes();
    _deletedNotes = await _noteService.getAllDeletedNotes();

    await _refreshTagAssignments();
    _validateSelection();
  }

  Future<void> _refreshTags() async {
    _tags = await _noteService.getAllTags();

    final validTagIds = _tags.map((tag) => tag.id).toSet();
    _selectedTagIds.removeWhere((id) => !validTagIds.contains(id));

    await _refreshTagAssignments();
  }

  Future<void> _refreshTagAssignments() async {
    if (_tags.isEmpty) {
      _noteIdsByTag = {};
      _tagsByNoteId = {};
      return;
    }

    final entries = await Future.wait(
      _tags.map((tag) async {
        final notes = await _noteService.getNotesForTag(tag.id);

        return MapEntry(tag, notes);
      }),
    );

    final noteIdsByTag = <int, Set<String>>{};
    final tagsByNoteId = <String, List<Tag>>{};

    for (final entry in entries) {
      final tag = entry.key;
      final notes = entry.value;

      noteIdsByTag[tag.id] = notes.map((note) => note.id).toSet();

      for (final note in notes) {
        tagsByNoteId.putIfAbsent(note.id, () => []).add(tag);
      }
    }

    _noteIdsByTag = noteIdsByTag;
    _tagsByNoteId = tagsByNoteId;
  }

  void _validateSelection() {
    if (_selectedNoteId == null) return;

    final exists = _activeNotes.any((note) => note.id == _selectedNoteId);

    if (!exists) {
      _selectedNoteId = null;
    }
  }

  // Selection

  bool selectNote(String? id) {
    if (id != null && !_activeNotes.any((note) => note.id == id)) {
      return false;
    }

    if (_selectedNoteId == id) return true;

    _selectedNoteId = id;
    notifyListeners();
    return true;
  }

  void clearSelection() {
    selectNote(null);
  }

  // Notes

  Future<Note> createNote({String content = ''}) {
    return _run(() async {
      final note = await _noteService.createNote(content: content);

      await _refreshNotes();
      _selectedNoteId = note.id;

      return note;
    });
  }

  Future<Note> updateNoteContent(String id, String content) {
    return _run(() async {
      final note = await _noteService.updateNoteContent(id, content);

      await _refreshNotes();

      return note;
    });
  }

  Future<bool> deleteNote(String id) {
    return _run(() async {
      final deleted = await _noteService.deleteNote(id);

      if (deleted) {
        await _refreshNotes();
      }

      return deleted;
    });
  }

  Future<bool> restoreNote(String id) {
    return _run(() async {
      final restored = await _noteService.restoreNote(id);

      if (restored) {
        await _refreshNotes();
      }

      return restored;
    });
  }

  Future<bool> permanentlyDeleteNote(String id) {
    return _run(() async {
      final deleted = await _noteService.permanentlyDeleteNote(id);

      if (deleted) {
        await _refreshNotes();
      }

      return deleted;
    });
  }

  Future<int> permanentlyDeleteAllNotes() {
    return _run(() async {
      final deletedCount = await _noteService.permanentlyDeleteAllNotes();

      if (deletedCount > 0) {
        await _refreshNotes();
      }

      return deletedCount;
    });
  }

  // Tags

  Future<Tag> createTag(String name) {
    return _run(() async {
      final tag = await _noteService.createTag(name);

      await _refreshTags();

      return tag;
    });
  }

  Future<bool> renameTag(int tagId, String newName) {
    return _run(() async {
      final renamed = await _noteService.renameTag(tagId, newName);

      if (renamed) {
        await _refreshTags();
        await _refreshNotes();
      }

      return renamed;
    });
  }

  Future<bool> deleteTag(int tagId) {
    return _run(() async {
      final deleted = await _noteService.deleteTag(tagId);

      if (deleted) {
        await _refreshTags();
        await _refreshNotes();
      }

      return deleted;
    });
  }

  Future<bool> assignTag(String noteId, int tagId) {
    return _run(() async {
      final assigned = await _noteService.assignTag(noteId, tagId);

      if (assigned) {
        await _refreshNotes();
      }

      return assigned;
    });
  }

  Future<bool> removeTag(String noteId, int tagId) {
    return _run(() async {
      final removed = await _noteService.removeTag(noteId, tagId);

      if (removed) {
        await _refreshNotes();
      }

      return removed;
    });
  }

  Future<List<Tag>> getTagsForNote(String noteId) {
    return _noteService.getTagsForNote(noteId);
  }

  Future<List<Note>> getNotesForTag(int tagId) {
    return _noteService.getNotesForTag(tagId);
  }

  // Internal operation handling

  Future<T> _run<T>(Future<T> Function() operation) async {
    _error = null;
    _pendingOperations++;
    notifyListeners();

    try {
      return await operation();
    } catch (error) {
      _error = error;
      rethrow;
    } finally {
      _pendingOperations--;
      notifyListeners();
    }
  }

  void clearError() {
    if (_error == null) return;

    _error = null;
    notifyListeners();
  }
}
