// Copyright 2026 WITHLET11 <withlet11@gmail.com>
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:provider/provider.dart';

import '../models/note.dart';
import '../models/tag.dart';
import '../providers/notes_provider.dart';
import '../services/markdown_export_service.dart';
import '../utils/markdown_formatting.dart';
import '../utils/note_title.dart';

class _SaveNoteIntent extends Intent {
  const _SaveNoteIntent();
}

class _FormatNoteIntent extends Intent {
  const _FormatNoteIntent(this.format);

  final MarkdownFormat format;
}

class _DismissFormattingToolbarIntent extends Intent {
  const _DismissFormattingToolbarIntent();
}

class NoteDetailPane extends StatefulWidget {
  const NoteDetailPane({
    super.key,
    this.showBackButton = false,
    this.onBack,
    this.markdownExportService,
  });

  final bool showBackButton;
  final VoidCallback? onBack;
  final MarkdownExportService? markdownExportService;

  @override
  State<NoteDetailPane> createState() => NoteDetailPaneState();
}

class NoteDetailPaneState extends State<NoteDetailPane> {
  static const _debounceDuration = Duration(milliseconds: 500);

  final _editorFocusNode = FocusNode();
  final _controller = TextEditingController();
  final _defaultMarkdownExportService = MarkdownExportService();
  final _formattingMenuController = MenuController();

  MarkdownExportService get _markdownExportService =>
      widget.markdownExportService ?? _defaultMarkdownExportService;

  Timer? _debounce;
  String? _editingNoteId;
  Future<bool>? _saveFuture;
  bool _hasUnsavedChanges = false;
  bool _isPreview = false;
  bool _isSaving = false;
  Object? _saveError;
  bool _isExporting = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _editorFocusNode.dispose();
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

  Future<bool> savePendingChanges() {
    _debounce?.cancel();
    _debounce = null;

    final inProgress = _saveFuture;
    if (inProgress != null) return inProgress;

    late final Future<bool> future;

    future = _savePendingChanges().whenComplete(() {
      if (identical(_saveFuture, future)) {
        _saveFuture = null;
      }
    });

    _saveFuture = future;
    return future;
  }

  Future<bool> _savePendingChanges() async {
    while (_hasUnsavedChanges) {
      _debounce?.cancel();
      _debounce = null;

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

  Future<void> _exportNote(Note note) async {
    if (_isExporting) return;

    final canSave = await savePendingChanges();

    if (!canSave || !mounted) return;

    setState(() {
      _isExporting = true;
    });

    final messenger = ScaffoldMessenger.of(context);

    try {
      final result = await _markdownExportService.exportNote(
        note.copyWith(content: _controller.text),
      );

      if (!mounted) return;

      if (result != null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Note exported successfully.')),
        );
      }
    } catch (error) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Could not export note: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Future<void> _deleteNote(Note note) async {
    final canDelete = await savePendingChanges();

    if (!canDelete || !mounted) return;

    final provider = context.read<NotesProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final title = deriveNoteTitle(note.content);

    try {
      final deleted = await provider.deleteNote(note.id);

      if (!mounted) return;

      if (!deleted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Could not delete note.')),
        );
        return;
      }

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('"$title" moved to Trash'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              unawaited(
                _restoreDeletedNote(provider, note.id, title, messenger),
              );
            },
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Could not delete note: $error')),
        );
      }
    }
  }

  Future<void> _restoreDeletedNote(
    NotesProvider provider,
    String noteId,
    String title,
    ScaffoldMessengerState messenger,
  ) async {
    try {
      final restored = await provider.restoreNote(noteId);

      if (!messenger.mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            restored ? '"$title" restored' : 'Could not restore note.',
          ),
        ),
      );
    } catch (error) {
      if (messenger.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Could not restore note: $error')),
        );
      }
    }
  }

  Widget _buildMarkdownPreview(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity,
        child: MarkdownBody(
          data: _controller.text,
          selectable: true,
          styleSheet: MarkdownStyleSheet(
            p: textTheme.bodyLarge,
            h1: textTheme.headlineMedium,
            h2: textTheme.headlineSmall,
            h3: textTheme.titleLarge,
            h4: textTheme.titleMedium,
            h5: textTheme.titleSmall,
            h6: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
            blockquote: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
            blockquoteDecoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
              border: Border(
                left: BorderSide(color: colorScheme.primary, width: 4),
              ),
            ),
            code: textTheme.bodyMedium?.copyWith(
              fontFamily: 'monospace',
              backgroundColor: colorScheme.surfaceContainerHighest,
            ),
            codeblockDecoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            codeblockPadding: const EdgeInsets.all(16),
            listBullet: textTheme.bodyLarge,
            a: textTheme.bodyLarge?.copyWith(
              color: colorScheme.primary,
              decoration: TextDecoration.underline,
            ),
            horizontalRuleDecoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _applyFormatting(MarkdownFormat format) {
    if (_isPreview || _editingNoteId == null) return;

    final result = applyMarkdownFormat(
      _controller.text,
      _controller.selection,
      format,
    );

    _controller.value = TextEditingValue(
      text: result.text,
      selection: result.selection,
      composing: TextRange.empty,
    );

    _editorFocusNode.requestFocus();
    _onChanged(_controller.text);
  }

  Widget _buildFormattingMenu(Note? note) {
    return MenuAnchor(
      controller: _formattingMenuController,
      menuChildren: [
        _NoteFormattingToolbar(onFormat: _applyFormattingFromToolbar),
      ],
      builder: (context, controller, child) {
        return IconButton(
          tooltip: 'Text formatting',
          onPressed: note == null || _isPreview
              ? null
              : () {
                  if (controller.isOpen) {
                    controller.close();
                  } else {
                    controller.open();
                  }
                },
          icon: const Icon(Icons.text_fields),
        );
      },
    );
  }

  void _applyFormattingFromToolbar(MarkdownFormat format) {
    _formattingMenuController.close();
    _applyFormatting(format);
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.keyS, control: true):
            _SaveNoteIntent(),
        SingleActivator(LogicalKeyboardKey.keyB, control: true):
            _FormatNoteIntent(MarkdownFormat.bold),
        SingleActivator(LogicalKeyboardKey.keyI, control: true):
            _FormatNoteIntent(MarkdownFormat.italic),
        SingleActivator(LogicalKeyboardKey.keyX, control: true, shift: true):
            _FormatNoteIntent(MarkdownFormat.strikethrough),
        SingleActivator(LogicalKeyboardKey.keyK, control: true):
            _FormatNoteIntent(MarkdownFormat.link),
        SingleActivator(LogicalKeyboardKey.digit8, control: true, shift: true):
            _FormatNoteIntent(MarkdownFormat.bulletedList),
        SingleActivator(LogicalKeyboardKey.digit7, control: true, shift: true):
            _FormatNoteIntent(MarkdownFormat.numberedList),
        SingleActivator(LogicalKeyboardKey.keyC, control: true, shift: true):
            _FormatNoteIntent(MarkdownFormat.inlineCode),
        SingleActivator(LogicalKeyboardKey.escape):
            _DismissFormattingToolbarIntent(),
      },
      child: Actions(
        actions: {
          _SaveNoteIntent: CallbackAction<_SaveNoteIntent>(
            onInvoke: (_) {
              unawaited(savePendingChanges());
              return null;
            },
          ),
          _FormatNoteIntent: CallbackAction<_FormatNoteIntent>(
            onInvoke: (intent) {
              _applyFormatting(intent.format);
              return null;
            },
          ),
          _DismissFormattingToolbarIntent:
              CallbackAction<_DismissFormattingToolbarIntent>(
                onInvoke: (_) {
                  _formattingMenuController.close();
                  return null;
                },
              ),
        },
        child: Consumer<NotesProvider>(
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
                  _buildFormattingMenu(note),
                  IconButton(
                    tooltip: 'Export as Markdown',
                    onPressed: note == null || _isExporting
                        ? null
                        : () => _exportNote(note),
                    icon: _isExporting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.file_download_outlined),
                  ),
                  IconButton(
                    tooltip: 'Move to Trash',
                    onPressed: note == null || provider.isLoading
                        ? null
                        : () => _deleteNote(note),
                    icon: const Icon(Icons.delete_outline),
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
                  ? const Center(
                      child: Text('Select a note or create a new one.'),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: _isPreview
                              ? _buildMarkdownPreview(context)
                              : Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: TextField(
                                    controller: _controller,
                                    focusNode: _editorFocusNode,
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
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }
}

class _NoteFormattingToolbar extends StatelessWidget {
  const _NoteFormattingToolbar({required this.onFormat});

  final ValueChanged<MarkdownFormat> onFormat;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Wrap(
        spacing: 2,
        runSpacing: 2,
        children: [
          _button(Icons.format_bold, 'Bold (Ctrl+B)', MarkdownFormat.bold),
          _button(
            Icons.format_italic,
            'Italic (Ctrl+I)',
            MarkdownFormat.italic,
          ),
          _button(
            Icons.strikethrough_s,
            'Strikethrough (Ctrl+Shift+X)',
            MarkdownFormat.strikethrough,
          ),
          _button(Icons.link, 'Link (Ctrl+K)', MarkdownFormat.link),
          _button(
            Icons.format_list_bulleted,
            'Bulleted list (Ctrl+Shift+8)',
            MarkdownFormat.bulletedList,
          ),
          _button(
            Icons.format_list_numbered,
            'Numbered list (Ctrl+Shift+7)',
            MarkdownFormat.numberedList,
          ),
          _button(
            Icons.code,
            'Inline code (Ctrl+Shift+C)',
            MarkdownFormat.inlineCode,
          ),
          _button(
            Icons.integration_instructions,
            'Code block',
            MarkdownFormat.codeBlock,
          ),
          _button(Icons.format_quote, 'Blockquote', MarkdownFormat.blockquote),
          _button(
            Icons.horizontal_rule,
            'Horizontal rule',
            MarkdownFormat.horizontalRule,
          ),
        ],
      ),
    );
  }

  Widget _button(IconData icon, String tooltip, MarkdownFormat format) {
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      onPressed: () => onFormat(format),
      icon: Icon(icon),
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
              selected: true,
              showCheckmark: false,
              visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              shape: const StadiumBorder(),
              color: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Theme.of(context).colorScheme.primary;
                }
                return null;
              }),
              labelPadding: const EdgeInsets.only(left: 8, right: 0),
              labelStyle: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              deleteIconColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          ActionChip(
            avatar: const Icon(Icons.add, size: 16),
            label: const Text('Add tag'),
            labelPadding: const EdgeInsets.only(left: 0, right: 8),
            onPressed: onAdd,
            visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            shape: const StadiumBorder(),
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
