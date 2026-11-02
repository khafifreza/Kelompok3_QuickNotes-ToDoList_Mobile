import 'package:flutter/material.dart';

import '../database/db_helper.dart';
import '../models/note_model.dart';
import 'note_editor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _accent = Color(0xFFA99AFF);
  static const _surface = Color(0xFF1B1B21);
  static const _muted = Color(0xFF92919D);

  List<Note> _notes = [];
  bool _isLoading = true;
  bool _showPinnedOnly = false;
  bool _sortByTitle = false;
  bool _sortAscending = false;
  int _refreshGeneration = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshNotes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshNotes({String query = ''}) async {
    final generation = ++_refreshGeneration;
    setState(() => _isLoading = true);
    try {
      final data = await DBHelper.instance.readAllNotes(
        searchQuery: query,
        pinnedOnly: _showPinnedOnly,
      );
      if (_sortByTitle) {
        data.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
      }
      final sortedData = _sortAscending ? data.reversed.toList() : data;
      if (!mounted || generation != _refreshGeneration) return;
      setState(() {
        _notes = sortedData;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted || generation != _refreshGeneration) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not load notes: $error')));
    }
  }

  Future<void> _deleteNote(Note note) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete note?'),
        content: const Text('This note will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete != true) return;

    await DBHelper.instance.deleteNote(note.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Note deleted')));
    await _refreshNotes(query: _searchController.text);
  }

  Future<void> _togglePin(Note note) async {
    await DBHelper.instance.updateNote(
      Note(
        id: note.id,
        title: note.title,
        content: note.content,
        createdAt: note.createdAt,
        isPinned: !note.isPinned,
      ),
    );
    if (!mounted) return;
    await _refreshNotes(query: _searchController.text);
  }

  Future<void> _openEditor({Note? note}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NoteEditorScreen(note: note)),
    );
    if (!mounted) return;
    await _refreshNotes(query: _searchController.text);
  }

  Future<void> _setPinnedFilter(bool value) async {
    setState(() => _showPinnedOnly = value);
    await _refreshNotes(query: _searchController.text);
  }

  String _formatTime(String createdAt) {
    final date = DateTime.tryParse(createdAt);
    if (date == null) return '';
    return MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay.fromDateTime(date));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: _accent,
        foregroundColor: const Color(0xFF17151F),
        onPressed: () => _openEditor(),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'My notes',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.8,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'A little space for your mind.',
                              style: TextStyle(color: _muted, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<bool>(
                        tooltip: 'Sort notes',
                        initialValue: _sortByTitle,
                        onSelected: (byTitle) {
                          setState(() {
                            _sortByTitle = byTitle;
                            _sortAscending = false;
                          });
                          _refreshNotes(query: _searchController.text);
                        },
                        color: _surface,
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: false,
                            child: Text('Recently added'),
                          ),
                          PopupMenuItem(
                            value: true,
                            child: Text('Title (A–Z)'),
                          ),
                        ],
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: _surface,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.tune, color: _muted),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => _refreshNotes(query: value),
                    decoration: InputDecoration(
                      hintText: 'Search your thoughts',
                      hintStyle: const TextStyle(color: _muted),
                      prefixIcon: const Icon(Icons.search, color: _muted),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close, color: _muted),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                                _refreshNotes();
                              },
                            ),
                      filled: true,
                      fillColor: _surface,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _NoteTab(
                        label: 'All notes',
                        count: _showPinnedOnly ? null : _notes.length,
                        selected: !_showPinnedOnly,
                        onTap: () => _setPinnedFilter(false),
                      ),
                      const SizedBox(width: 20),
                      _NoteTab(
                        label: 'Pinned',
                        selected: _showPinnedOnly,
                        onTap: () => _setPinnedFilter(true),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: _sortAscending
                            ? 'Sort newest first'
                            : 'Reverse sort order',
                        onPressed: () {
                          setState(() => _sortAscending = !_sortAscending);
                          _refreshNotes(query: _searchController.text);
                        },
                        icon: const Icon(Icons.sort, color: _muted, size: 20),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _notes.isEmpty
                  ? Center(
                      child: Text(
                        _showPinnedOnly
                            ? 'No pinned notes yet.'
                            : 'No notes found.',
                        style: const TextStyle(color: _muted),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                      itemCount: _notes.length,
                      itemBuilder: (context, index) {
                        final note = _notes[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          color: note.isPinned
                              ? const Color(0xFF272536)
                              : _surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: note.isPinned
                                  ? const Color(0xFF46405F)
                                  : Colors.transparent,
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => _openEditor(note: note),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                14,
                                10,
                                14,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          note.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        tooltip: note.isPinned
                                            ? 'Unpin note'
                                            : 'Pin note',
                                        onPressed: () => _togglePin(note),
                                        icon: Icon(
                                          note.isPinned
                                              ? Icons.push_pin
                                              : Icons.push_pin_outlined,
                                          color: note.isPinned
                                              ? _accent
                                              : _muted,
                                          size: 19,
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        tooltip: 'More note actions',
                                        color: _surface,
                                        onSelected: (action) {
                                          if (action == 'delete') {
                                            _deleteNote(note);
                                          }
                                        },
                                        itemBuilder: (context) => const [
                                          PopupMenuItem(
                                            value: 'delete',
                                            child: Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  if (note.content.isNotEmpty) ...[
                                    Text(
                                      note.content,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFFC3C1CC),
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                  Row(
                                    children: [
                                      Text(
                                        _formatTime(note.createdAt),
                                        style: const TextStyle(
                                          color: _muted,
                                          fontSize: 11,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        '·',
                                        style: TextStyle(color: _muted),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        note.isPinned ? 'Pinned' : 'Note',
                                        style: const TextStyle(
                                          color: _accent,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteTab extends StatelessWidget {
  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  const _NoteTab({
    required this.label,
    this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFFF4F2FA) : const Color(0xFF92919D);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 6),
              Text(
                '$count',
                style: const TextStyle(color: Color(0xFF92919D), fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
