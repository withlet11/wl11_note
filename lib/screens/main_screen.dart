// Copyright 2026 WITHLET11 <withlet11@gmail.com>
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/note.dart';
import '../models/tag.dart';
import '../providers/notes_provider.dart';
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

class NoteListPane extends StatelessWidget {
  const NoteListPane({
    super.key,
    required this.onCreateNote,
    required this.onSelectNote,
  });

  final VoidCallback onCreateNote;
  final ValueChanged<String> onSelectNote;

  void _showTagManagementDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => const _TagManagementDialog(),
    );
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
            title: const Text('wl11_note'),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                tooltip: 'New note',
                onPressed: provider.isLoading ? null : onCreateNote,
                icon: const Icon(Icons.add),
              ),
              IconButton(
                tooltip: 'Manage tags',
                onPressed: () => _showTagManagementDialog(context),
                icon: const Icon(Icons.sell_outlined),
              ),
            ],
          ),
          body: Column(
            children: [
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
              if (provider.tags.isNotEmpty)
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      ...provider.tags.map((tag) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(tag.name),
                            selected: provider.isTagSelected(tag.id),
                            onSelected: (_) {
                              provider.toggleTagFilter(tag.id);
                            },
                          ),
                        );
                      }),
                      if (provider.selectedTagIds.isNotEmpty)
                        TextButton(
                          onPressed: provider.clearTagFilters,
                          child: const Text('Clear'),
                        ),
                    ],
                  ),
                ),
              Expanded(
                child: notes.isEmpty
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
                            onTap: () => onSelectNote(note.id),
                            onTagTap: provider.toggleTagFilter,
                          );
                        },
                      ),
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
              runSpacing: 0,
              children: tags.map((tag) {
                return FilterChip(
                  label: Text(tag.name),
                  selected: selectedTagIds.contains(tag.id),
                  onSelected: (_) => onTagTap(tag.id),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: EdgeInsets.zero,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 6),
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
                  title: Text(tag.name),
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
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
