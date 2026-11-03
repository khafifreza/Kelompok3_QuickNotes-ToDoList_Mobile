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
  static const _accent = Color(0xFF32866A);
  static const _surface = Color(0xFFFFFFFF);
  static const _muted = Color(0xFF7C8790);
  static const _noteColors = [
    Color(0xFFFFF0B8),
    Color(0xFFD8F1F4),
    Color(0xFFE9DDF7),
    Color(0xFFFFE2CF),
    Color(0xFFE3E9F1),
    Color(0xFFDDF0E4),
  ];

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

  Widget _buildNoteCard(Note note, int index) {
    final cardColor = note.isPinned
        ? const Color(0xFFE0F0E7)
        : _noteColors[index % _noteColors.length];

    return Card(
      margin: const EdgeInsets.all(6),
      color: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openEditor(note: note),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
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
                        color: Color(0xFF28312E),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: note.isPinned ? 'Unpin note' : 'Pin note',
                    onPressed: () => _togglePin(note),
                    icon: Icon(
                      note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                      color: note.isPinned ? _accent : const Color(0xFF68736F),
                      size: 18,
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'More note actions',
                    color: _surface,
                    onSelected: (action) {
                      if (action == 'delete') _deleteNote(note);
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Color(0xFF68736F),
                      size: 20,
                    ),
                  ),
                ],
              ),
              if (note.content.isNotEmpty) ...[
                Text(
                  note.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF59645F), height: 1.4),
                ),
                const Spacer(),
              ] else
                const Spacer(),
              Row(
                children: [
                  Text(
                    note.isPinned ? 'Pinned' : 'Note',
                    style: const TextStyle(
                      color: Color(0xFF53645C),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatTime(note.createdAt),
                    style: const TextStyle(
                      color: Color(0xFF68736F),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
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
                              'Quick Notes',
                              style: TextStyle(
                                color: Color(0xFF26312D),
                                fontSize: 27,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
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
                          decoration: BoxDecoration(
                            color: _surface,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.tune,
                            color: Color(0xFF44524B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => _refreshNotes(query: value),
                    decoration: InputDecoration(
                      hintText: 'Search your notes',
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
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _NoteTab(
                        label: 'All',
                        count: _showPinnedOnly ? null : _notes.length,
                        selected: !_showPinnedOnly,
                        onTap: () => _setPinnedFilter(false),
                      ),
                      const SizedBox(width: 8),
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
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth >= 700) {
                          return GridView.builder(
                            padding: const EdgeInsets.fromLTRB(24, 4, 24, 96),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 1.8,
                                ),
                            itemCount: _notes.length,
                            itemBuilder: (context, index) =>
                                _buildNoteCard(_notes[index], index),
                          );
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                          itemCount: _notes.length,
                          itemBuilder: (context, index) => SizedBox(
                            height: 150,
                            child: _buildNoteCard(_notes[index], index),
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
    final color = selected ? Colors.white : const Color(0xFF6F7B75);
    return Material(
      color: selected ? const Color(0xFF32866A) : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                Text('$count', style: TextStyle(color: color, fontSize: 11)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
