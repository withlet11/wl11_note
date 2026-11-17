// Copyright 2026 WITHLET11 <withlet11@gmail.com>
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/note.dart';
import '../models/tag.dart';
import '../providers/notes_provider.dart';
import '../utils/note_title.dart';

class NoteDetailPane extends StatefulWidget {
  const NoteDetailPane({super.key, this.showBackButton = false, this.onBack});

  final bool showBackButton;
  final VoidCallback? onBack;

  @override
  NoteDetailPaneState createState() => NoteDetailPaneState();
}

class NoteDetailPaneState extends State<NoteDetailPane> {
  static const _debounceDuration = Duration(milliseconds: 500);

  final _controller = TextEditingController();

  Timer? _debounce;
  String? _editingNoteId;
  bool _hasUnsavedChanges = false;
  bool _isPreview = false;
  bool _isSaving = false;
  Object? _saveError;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _loadNote(Note? note) {
    if (_editingNoteId == note?.id) return;

    _debounce?.cancel();
    _editingNoteId = note?.id;
    _isPreview = false;
    _hasUnsavedChanges = false;
    _saveError = null;

    _controller.value = TextEditingValue(
      text: note?.content ?? '',
      selection: TextSelection.collapsed(offset: note?.content.length ?? 0),
    );
  }

  void _onChanged(String value) {
    _hasUnsavedChanges = true;
    _saveError = null;

    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () {
      unawaited(savePendingChanges().then((_) {}));
    });

    setState(() {});
  }

  Future<bool> savePendingChanges() async {
    _debounce?.cancel();
    _debounce = null;

    while (_hasUnsavedChanges) {
      final noteId = _editingNoteId;
      if (noteId == null) return true;

      final content = _controller.text;
      _hasUnsavedChanges = false;

      setState(() {
        _isSaving = true;
        _saveError = null;
      });

      try {
        await context.read<NotesProvider>().updateNoteContent(noteId, content);
      } catch (error) {
        _hasUnsavedChanges = true;

        if (mounted) {
          setState(() {
            _saveError = error;
            _isSaving = false;
          });
        }

        return false;
      }

      if (!mounted) return true;

      setState(() {
        _isSaving = false;
      });
    }

    return true;
  }

  void _showTagDialog(BuildContext context, String noteId) {
    showDialog<void>(
      context: context,
      builder: (_) => _AddTagDialog(noteId: noteId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotesProvider>(
      builder: (context, provider, child) {
        final note = provider.selectedNote;
        _loadNote(note);

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            leading: widget.showBackButton
                ? IconButton(
                    tooltip: 'Back to notes',
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.arrow_back),
                  )
                : null,
            title: Text(
              note == null
                  ? 'No note selected'
                  : deriveNoteTitle(_controller.text),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              TextButton(
                onPressed: note == null
                    ? null
                    : () {
                        setState(() {
                          _isPreview = !_isPreview;
                        });
                      },
                child: Text(_isPreview ? 'Edit' : 'Preview'),
              ),
              IconButton(
                tooltip: 'Manage note tags',
                onPressed: note == null
                    ? null
                    : () => _showTagDialog(context, note.id),
                icon: const Icon(Icons.sell_outlined),
              ),
              if (_isSaving)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else if (_saveError != null)
                IconButton(
                  tooltip: 'Save failed. Retry',
                  onPressed: () {
                    unawaited(savePendingChanges().then((_) {}));
                  },
                  icon: const Icon(Icons.error_outline),
                )
              else if (!_hasUnsavedChanges && note != null)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: Icon(Icons.cloud_done_outlined, size: 20),
                  ),
                ),
            ],
          ),
          body: note == null
              ? const Center(child: Text('Select a note or create a new one.'))
              : Column(
                  children: [
                    _NoteTagsRow(
                      tags: provider.tagsForNote(note.id),
                      onAdd: () => _showTagDialog(context, note.id),
                      onRemove: (tagId) {
                        unawaited(
                          provider
                              .removeTag(note.id, tagId)
                              .catchError((Object error) => false),
                        );
                      },
                    ),
                    Expanded(
                      child: _isPreview
                          ? SingleChildScrollView(
                              padding: const EdgeInsets.all(24),
                              child: MarkdownBody(
                                data: _controller.text,
                                selectable: true,
                              ),
                            )
                          : Padding(
                              padding: const EdgeInsets.all(24),
                              child: TextField(
                                controller: _controller,
                                onChanged: _onChanged,
                                expands: true,
                                maxLines: null,
                                minLines: null,
                                textAlignVertical: TextAlignVertical.top,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Start writing...',
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _NoteTagsRow extends StatelessWidget {
  const _NoteTagsRow({
    required this.tags,
    required this.onAdd,
    required this.onRemove,
  });

  final List<Tag> tags;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          ...tags.map(
            (tag) => InputChip(
              label: Text(tag.name),
              onDeleted: () => onRemove(tag.id),
              visualDensity: VisualDensity.compact,
            ),
          ),
          ActionChip(
            avatar: const Icon(Icons.add, size: 18),
            label: const Text('Add tag'),
            onPressed: onAdd,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _AddTagDialog extends StatefulWidget {
  const _AddTagDialog({required this.noteId});

  final String noteId;

  @override
  State<_AddTagDialog> createState() => _AddTagDialogState();
}

class _AddTagDialogState extends State<_AddTagDialog> {
  final _controller = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _assignExistingTag(int tagId) async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      await context.read<NotesProvider>().assignTag(widget.noteId, tagId);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _createAndAssignTag() async {
    if (_isSubmitting) return;

    final name = _controller.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final provider = context.read<NotesProvider>();
      final tag = await provider.createTag(name);

      await provider.assignTag(widget.noteId, tag.id);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showError(Object error) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Could not add tag: $error')));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotesProvider>(
      builder: (context, provider, child) {
        final assignedTagIds = provider
            .tagsForNote(widget.noteId)
            .map((tag) => tag.id)
            .toSet();

        final availableTags = provider.tags
            .where((tag) => !assignedTagIds.contains(tag.id))
            .toList();

        return AlertDialog(
          title: const Text('Add tag'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (availableTags.isNotEmpty) ...[
                  const Text('Existing tags'),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 240),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: availableTags.length,
                      itemBuilder: (context, index) {
                        final tag = availableTags[index];

                        return ListTile(
                          dense: true,
                          title: Text(tag.name),
                          trailing: const Icon(Icons.add),
                          enabled: !_isSubmitting,
                          onTap: () => _assignExistingTag(tag.id),
                        );
                      },
                    ),
                  ),
                  const Divider(),
                ],
                TextField(
                  controller: _controller,
                  onChanged: (_) => setState(() {}),
                  autofocus: availableTags.isEmpty,
                  enabled: !_isSubmitting,
                  decoration: const InputDecoration(
                    labelText: 'Create a new tag',
                    hintText: 'Enter tag name',
                  ),
                  onSubmitted: (_) => _createAndAssignTag(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isSubmitting
                  ? null
                  : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: _isSubmitting || _controller.text.trim().isEmpty
                  ? null
                  : _createAndAssignTag,
              child: const Text('Create and add'),
            ),
          ],
        );
      },
    );
  }
}
