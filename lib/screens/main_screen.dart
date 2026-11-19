// Copyright 2026 WITHLET11 <withlet11@gmail.com>
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/note.dart';
import '../models/tag.dart';
import '../providers/notes_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/note_title.dart';
import 'note_detail_pane.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const double _desktopBreakpoint = 700;

  final _detailPaneKey = GlobalKey<NoteDetailPaneState>();

  Future<void> _createNote(NotesProvider provider) async {
    final canContinue =
        await _detailPaneKey.currentState?.savePendingChanges() ?? true;

    if (!canContinue) return;

    try {
      await provider.createNote();
    } catch (_) {
      // The provider retains the error.
    }
  }

  Future<void> _selectNote(NotesProvider provider, String noteId) async {
    final canContinue =
        await _detailPaneKey.currentState?.savePendingChanges() ?? true;

    if (!canContinue) return;

    provider.selectNote(noteId);
  }

  Future<void> _clearSelection(NotesProvider provider) async {
    final canContinue =
        await _detailPaneKey.currentState?.savePendingChanges() ?? true;

    if (!canContinue) return;

    provider.clearSelection();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<NotesProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.activeNotes.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.hasError && provider.activeNotes.isEmpty) {
            return _ErrorView(
              error: provider.error,
              onRetry: () {
                unawaited(provider.initialize().catchError((Object error) {}));
              },
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= _desktopBreakpoint) {
                return _DesktopLayout(
                  detailPaneKey: _detailPaneKey,
                  onCreateNote: () => _createNote(provider),
                  onSelectNote: (id) => _selectNote(provider, id),
                );
              }

              return _MobileLayout(
                detailPaneKey: _detailPaneKey,
                onCreateNote: () => _createNote(provider),
                onSelectNote: (id) => _selectNote(provider, id),
                onBack: () => _clearSelection(provider),
              );
            },
          );
        },
      ),
    );
  }
}

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({
    required this.detailPaneKey,
    required this.onCreateNote,
    required this.onSelectNote,
  });

  final GlobalKey<NoteDetailPaneState> detailPaneKey;
  final VoidCallback onCreateNote;
  final ValueChanged<String> onSelectNote;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 280,
          child: NoteListPane(
            onCreateNote: onCreateNote,
            onSelectNote: onSelectNote,
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(child: NoteDetailPane(key: detailPaneKey)),
      ],
    );
  }
}

class _MobileLayout extends StatelessWidget {
  const _MobileLayout({
    required this.detailPaneKey,
    required this.onCreateNote,
    required this.onSelectNote,
    required this.onBack,
  });

  final GlobalKey<NoteDetailPaneState> detailPaneKey;
  final VoidCallback onCreateNote;
  final ValueChanged<String> onSelectNote;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Consumer<NotesProvider>(
      builder: (context, provider, child) {
        if (provider.selectedNote != null) {
          return NoteDetailPane(
            key: detailPaneKey,
            showBackButton: true,
            onBack: onBack,
          );
        }

        return NoteListPane(
          onCreateNote: onCreateNote,
          onSelectNote: onSelectNote,
        );
      },
    );
  }
}

enum _NoteListView { notes, menu, trash }

enum _NoteSortOption {
  updatedDescending(
    'Updated date (newest first)',
    NoteSortField.updatedAt,
    SortDirection.descending,
  ),
  updatedAscending(
    'Updated date (oldest first)',
    NoteSortField.updatedAt,
    SortDirection.ascending,
  ),
  titleAscending(
    'Note name (A–Z)',
    NoteSortField.title,
    SortDirection.ascending,
  ),
  titleDescending(
    'Note name (Z–A)',
    NoteSortField.title,
    SortDirection.descending,
  ),
  createdDescending(
    'Created date (newest first)',
    NoteSortField.createdAt,
    SortDirection.descending,
  ),
  createdAscending(
    'Created date (oldest first)',
    NoteSortField.createdAt,
    SortDirection.ascending,
  );

  const _NoteSortOption(this.label, this.field, this.direction);

  final String label;
  final NoteSortField field;
  final SortDirection direction;
}

class NoteListPane extends StatefulWidget {
  const NoteListPane({
    super.key,
    required this.onCreateNote,
    required this.onSelectNote,
  });

  final VoidCallback onCreateNote;
  final ValueChanged<String> onSelectNote;

  @override
  State<NoteListPane> createState() => _NoteListPaneState();
}

class _NoteListPaneState extends State<NoteListPane> {
  _NoteListView _view = _NoteListView.notes;

  void _showTagManagementDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => const _TagManagementDialog(),
    );
  }

  Future<void> _restoreNote(
    BuildContext context,
    NotesProvider provider,
    Note note,
  ) async {
    try {
      await provider.restoreNote(note.id);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not restore note: $error')),
        );
      }
    }
  }

  Future<void> _permanentlyDeleteNote(
    BuildContext context,
    NotesProvider provider,
    Note note,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete permanently?'),
          content: Text(
            'Delete "${deriveNoteTitle(note.content)}" permanently? '
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete permanently'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await provider.permanentlyDeleteNote(note.id);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete note permanently: $error')),
        );
      }
    }
  }

  Future<void> _clearTrash() async {
    final provider = context.read<NotesProvider>();
    final count = provider.deletedNotes.length;

    if (count == 0) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Trash?'),
        content: Text(
          'Permanently delete $count '
          '${count == 1 ? 'note' : 'notes'}? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete forever'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final deletedCount = await provider.permanentlyDeleteAllNotes();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$deletedCount '
            '${deletedCount == 1 ? 'note' : 'notes'} permanently deleted',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not clear Trash: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotesProvider>(
      builder: (context, provider, child) {
        final notes = provider.filteredNotes;

        final hasFilters =
            provider.searchQuery.isNotEmpty ||
            provider.selectedTagIds.isNotEmpty;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              _view == _NoteListView.trash
                  ? 'Trash'
                  : _view == _NoteListView.menu
                  ? 'Settings'
                  : 'WL11note',
            ),
            automaticallyImplyLeading: false,
            leading: _view == _NoteListView.notes
                ? null
                : IconButton(
                    tooltip: 'Back',
                    onPressed: () {
                      setState(() {
                        _view = _view == _NoteListView.trash
                            ? _NoteListView.menu
                            : _NoteListView.notes;
                      });
                    },
                    icon: const Icon(Icons.arrow_back),
                  ),
            actions: [
              if (_view == _NoteListView.notes) ...[
                PopupMenuButton<_NoteSortOption>(
                  tooltip: 'Sort notes',
                  icon: const Icon(Icons.sort),
                  onSelected: (option) {
                    provider.setSorting(
                      field: option.field,
                      direction: option.direction,
                    );
                  },
                  itemBuilder: (context) {
                    return _NoteSortOption.values.map((option) {
                      return CheckedPopupMenuItem<_NoteSortOption>(
                        value: option,
                        checked:
                            provider.sortField == option.field &&
                            provider.sortDirection == option.direction,
                        child: Text(option.label),
                      );
                    }).toList();
                  },
                ),
                IconButton(
                  tooltip: 'New note',
                  onPressed: provider.isLoading ? null : widget.onCreateNote,
                  icon: const Icon(Icons.add),
                ),
                IconButton(
                  tooltip: 'Manage tags',
                  onPressed: () => _showTagManagementDialog(context),
                  icon: const Icon(Icons.sell_outlined),
                ),
                IconButton(
                  tooltip: 'Menu',
                  onPressed: () {
                    setState(() => _view = _NoteListView.menu);
                  },
                  icon: const Icon(Icons.menu),
                ),
              ],
              if (_view == _NoteListView.trash &&
                  provider.deletedNotes.isNotEmpty)
                IconButton(
                  tooltip: 'Clear Trash',
                  onPressed: provider.isLoading ? null : _clearTrash,
                  icon: const Icon(Icons.delete_sweep_outlined),
                ),
            ],
          ),
          body: Column(
            children: [
              if (_view == _NoteListView.notes) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                  child: TextField(
                    key: const ValueKey('noteSearchField'),
                    onChanged: provider.setSearchQuery,
                    decoration: InputDecoration(
                      hintText: 'Search notes',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: provider.searchQuery.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              onPressed: () => provider.setSearchQuery(''),
                              icon: const Icon(Icons.clear),
                            ),
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ],

              Expanded(
                child: switch (_view) {
                  _NoteListView.notes =>
                    notes.isEmpty
                        ? _FilteredEmptyView(
                            hasFilters: hasFilters,
                            onClear: () {
                              provider.setSearchQuery('');
                              provider.clearTagFilters();
                            },
                          )
                        : ListView.builder(
                            itemCount: notes.length,
                            itemBuilder: (context, index) {
                              final note = notes[index];

                              return _NoteListTile(
                                note: note,
                                tags: provider.tagsForNote(note.id),
                                selectedTagIds: provider.selectedTagIds,
                                selected: note.id == provider.selectedNoteId,
                                onTap: () => widget.onSelectNote(note.id),
                                onTagTap: provider.toggleTagFilter,
                              );
                            },
                          ),
                  _NoteListView.menu => ListView(
                    children: [
                      ExpansionTile(
                        leading: const Icon(Icons.palette_outlined),
                        title: const Text('Appearance'),
                        children: [
                          Consumer<ThemeProvider>(
                            builder: (context, provider, child) {
                              return RadioGroup<ThemeMode>(
                                groupValue: provider.themeMode,
                                onChanged: (mode) {
                                  if (mode != null) {
                                    unawaited(provider.setThemeMode(mode));
                                  }
                                },
                                child: Column(
                                  children: ThemeMode.values.map((mode) {
                                    return RadioListTile<ThemeMode>(
                                      title: Text(switch (mode) {
                                        ThemeMode.system => 'System default',
                                        ThemeMode.light => 'Light',
                                        ThemeMode.dark => 'Dark',
                                      }),
                                      value: mode,
                                    );
                                  }).toList(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      ExpansionTile(
                        leading: const Icon(Icons.text_fields),
                        title: const Text('Text size'),
                        children: [
                          Consumer<ThemeProvider>(
                            builder: (context, provider, child) {
                              return RadioGroup<AppTextSize>(
                                groupValue: provider.textSize,
                                onChanged: (size) {
                                  if (size != null) {
                                    unawaited(provider.setTextSize(size));
                                  }
                                },
                                child: Column(
                                  children: AppTextSize.values.map((size) {
                                    return RadioListTile<AppTextSize>(
                                      title: Text(switch (size) {
                                        AppTextSize.small => 'Small',
                                        AppTextSize.medium => 'Medium',
                                        AppTextSize.large => 'Large',
                                      }),
                                      value: size,
                                    );
                                  }).toList(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      ListTile(
                        leading: const Icon(Icons.delete_outline),
                        title: const Text('Trash'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          setState(() => _view = _NoteListView.trash);
                        },
                      ),
                    ],
                  ),
                  _NoteListView.trash => _TrashListView(
                    notes: provider.deletedNotes,
                    isLoading: provider.isLoading,
                    onRestore: (note) => _restoreNote(context, provider, note),
                    onDeletePermanently: (note) =>
                        _permanentlyDeleteNote(context, provider, note),
                  ),
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilteredEmptyView extends StatelessWidget {
  const _FilteredEmptyView({required this.hasFilters, required this.onClear});

  final bool hasFilters;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    if (!hasFilters) {
      return const _EmptyNotesView();
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 48),
            const SizedBox(height: 16),
            const Text('No matching notes'),
            const SizedBox(height: 8),
            const Text('Try a different search or tag filter.'),
            const SizedBox(height: 16),
            TextButton(onPressed: onClear, child: const Text('Clear filters')),
          ],
        ),
      ),
    );
  }
}

class _NoteListTile extends StatelessWidget {
  const _NoteListTile({
    required this.note,
    required this.tags,
    required this.selectedTagIds,
    required this.selected,
    required this.onTap,
    required this.onTagTap,
  });

  final Note note;
  final List<Tag> tags;
  final Set<int> selectedTagIds;
  final bool selected;
  final VoidCallback onTap;
  final ValueChanged<int> onTagTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selected: selected,
      title: Text(
        deriveNoteTitle(note.content),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_formatDate(note.updatedAt)),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 2,
              children: tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: selectedTagIds.contains(tag.id)
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tag.name,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: selectedTagIds.contains(tag.id)
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
      onTap: onTap,
    );
  }

  String _formatDate(DateTime date) {
    final localDate = date.toLocal();
    final now = DateTime.now();

    if (localDate.year == now.year &&
        localDate.month == now.month &&
        localDate.day == now.day) {
      return '${localDate.hour.toString().padLeft(2, '0')}:'
          '${localDate.minute.toString().padLeft(2, '0')}';
    }

    return '${localDate.year}-'
        '${localDate.month.toString().padLeft(2, '0')}-'
        '${localDate.day.toString().padLeft(2, '0')}';
  }
}

class _TrashListView extends StatelessWidget {
  const _TrashListView({
    required this.notes,
    required this.isLoading,
    required this.onRestore,
    required this.onDeletePermanently,
  });

  final List<Note> notes;
  final bool isLoading;
  final ValueChanged<Note> onRestore;
  final ValueChanged<Note> onDeletePermanently;

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) {
      return const _EmptyTrashView();
    }

    return ListView.builder(
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];

        return ListTile(
          title: Text(
            deriveNoteTitle(note.content),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text('Deleted ${_formatDeletionDate(note.deletedAt!)}'),
          trailing: Wrap(
            spacing: 0,
            children: [
              IconButton(
                tooltip: 'Restore note',
                onPressed: isLoading ? null : () => onRestore(note),
                icon: const Icon(Icons.restore),
              ),
              IconButton(
                tooltip: 'Delete permanently',
                onPressed: isLoading ? null : () => onDeletePermanently(note),
                icon: const Icon(Icons.delete_forever_outlined),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDeletionDate(DateTime date) {
    final localDate = date.toLocal();
    final now = DateTime.now();

    if (localDate.year == now.year &&
        localDate.month == now.month &&
        localDate.day == now.day) {
      return '${localDate.hour.toString().padLeft(2, '0')}:'
          '${localDate.minute.toString().padLeft(2, '0')}';
    }

    return '${localDate.year}-'
        '${localDate.month.toString().padLeft(2, '0')}-'
        '${localDate.day.toString().padLeft(2, '0')}';
  }
}

class _EmptyTrashView extends StatelessWidget {
  const _EmptyTrashView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline, size: 48),
            SizedBox(height: 16),
            Text('Trash is empty'),
          ],
        ),
      ),
    );
  }
}

class _EmptyNotesView extends StatelessWidget {
  const _EmptyNotesView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.note_add_outlined, size: 48),
            const SizedBox(height: 16),
            const Text('No notes yet'),
            const SizedBox(height: 8),
            const Text('Create a note to get started.'),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            const Text('Initialization failed'),
            const SizedBox(height: 8),
            Text(error.toString(), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _TagManagementDialog extends StatelessWidget {
  const _TagManagementDialog();

  Future<void> _renameTag(
    BuildContext context,
    NotesProvider provider,
    Tag tag,
  ) async {
    final controller = TextEditingController(text: tag.name);

    try {
      final newName = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Rename tag'),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Tag name'),
              onSubmitted: (value) {
                Navigator.pop(dialogContext, value);
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(dialogContext, controller.text);
                },
                child: const Text('Rename'),
              ),
            ],
          );
        },
      );

      if (newName == null || newName.trim().isEmpty) return;

      await provider.renameTag(tag.id, newName.trim());
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not rename tag: $error')));
      }
    } finally {
      controller.dispose();
    }
  }

  Future<void> _deleteTag(
    BuildContext context,
    NotesProvider provider,
    Tag tag,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete tag?'),
          content: Text(
            'Delete "${tag.name}"? '
            'It will be removed from all notes.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await provider.deleteTag(tag.id);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not delete tag: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Manage tags'),
      content: SizedBox(
        width: 360,
        child: Consumer<NotesProvider>(
          builder: (context, provider, child) {
            if (provider.tags.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('No tags created yet.')),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              itemCount: provider.tags.length,
              itemBuilder: (context, index) {
                final tag = provider.tags[index];

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    provider.isTagSelected(tag.id)
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                  ),
                  title: Text(tag.name),
                  onTap: provider.isLoading
                      ? null
                      : () => provider.toggleTagFilter(tag.id),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Rename tag',
                        onPressed: provider.isLoading
                            ? null
                            : () => _renameTag(context, provider, tag),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: 'Delete tag',
                        onPressed: provider.isLoading
                            ? null
                            : () => _deleteTag(context, provider, tag),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      actions: [
        Consumer<NotesProvider>(
          builder: (context, provider, child) {
            return TextButton(
              onPressed:
                  provider.tags.isEmpty || provider.selectedTagIds.isEmpty
                  ? null
                  : provider.clearTagFilters,
              child: const Text('Clear'),
            );
          },
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
