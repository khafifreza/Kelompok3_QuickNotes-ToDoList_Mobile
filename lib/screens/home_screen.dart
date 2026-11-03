import 'package:flutter/material.dart';

import '../database/db_helper.dart';
import '../models/note_model.dart';
import 'note_editor_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const HomeScreen({super.key, required this.onToggleTheme});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _accent = Color(0xFF32866A);
  static const _lightNoteColors = [
    Color(0xFFFFF0B8),
    Color(0xFFD8F1F4),
    Color(0xFFE9DDF7),
    Color(0xFFFFE2CF),
    Color(0xFFE3E9F1),
    Color(0xFFDDF0E4),
  ];
  static const _darkNoteColors = [
    Color(0xFF554A2B),
    Color(0xFF29464A),
    Color(0xFF443653),
    Color(0xFF553A2B),
    Color(0xFF34404F),
    Color(0xFF30483A),
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
      ).showSnackBar(SnackBar(content: Text('Gagal memuat catatan: $error')));
    }
  }

  Future<void> _deleteNote(Note note) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus catatan?'),
        content: const Text('Catatan ini akan dihapus secara permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (shouldDelete != true) return;

    await DBHelper.instance.deleteNote(note.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Catatan dihapus')));
    await _refreshNotes(query: _searchController.text);
  }

  Future<void> _togglePin(Note note) async {
    await DBHelper.instance.updateNote(
      Note(
        id: note.id,
        title: note.title,
        content: note.content,
        createdAt: note.createdAt,
        updatedAt: DateTime.now().toIso8601String(),
        isPinned: !note.isPinned,
      ),
    );
    if (!mounted) return;
    await _refreshNotes(query: _searchController.text);
  }

  Future<void> _openEditor({Note? note}) async {
    Note? openedNote = note;
    if (note != null) {
      openedNote = Note(
        id: note.id,
        title: note.title,
        content: note.content,
        createdAt: note.createdAt,
        updatedAt: DateTime.now().toIso8601String(),
        isPinned: note.isPinned,
      );
      try {
        await DBHelper.instance.updateNote(openedNote);
        if (!mounted) return;
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui catatan: $error')),
        );
        return;
      }
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditorScreen(note: openedNote),
      ),
    );
    if (!mounted) return;
    await _refreshNotes(query: _searchController.text);
  }

  Future<void> _setPinnedFilter(bool value) async {
    setState(() => _showPinnedOnly = value);
    await _refreshNotes(query: _searchController.text);
  }

  String _formatRelativeTime(String updatedAt) {
    final date = DateTime.tryParse(updatedAt);
    if (date == null) return '';

    final elapsed = DateTime.now().difference(date);
    if (elapsed.isNegative || elapsed.inMinutes < 1) return 'Baru saja';
    if (elapsed.inHours < 1) return '${elapsed.inMinutes} menit lalu';
    if (elapsed.inDays < 1) return '${elapsed.inHours} jam lalu';
    if (elapsed.inDays < 7) return '${elapsed.inDays} hari lalu';
    if (elapsed.inDays < 30) return '${elapsed.inDays ~/ 7} minggu lalu';
    if (elapsed.inDays < 365) return '${elapsed.inDays ~/ 30} bulan lalu';
    return '${elapsed.inDays ~/ 365} tahun lalu';
  }

  Widget _buildNoteCard(Note note, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = note.isPinned
        ? (isDark ? const Color(0xFF29483A) : const Color(0xFFE0F0E7))
        : (isDark ? _darkNoteColors : _lightNoteColors)[index %
              _lightNoteColors.length];

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
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: note.isPinned
                        ? 'Lepas sematan catatan'
                        : 'Sematkan catatan',
                    onPressed: () => _togglePin(note),
                    icon: Icon(
                      note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                      color: note.isPinned
                          ? _accent
                          : colorScheme.onSurfaceVariant,
                      size: 18,
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Aksi catatan lainnya',
                    color: colorScheme.surface,
                    onSelected: (action) {
                      if (action == 'delete') _deleteNote(note);
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'delete', child: Text('Hapus')),
                    ],
                    icon: const Icon(Icons.delete_outline, size: 20),
                  ),
                ],
              ),
              if (note.content.isNotEmpty) ...[
                Text(
                  note.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const Spacer(),
              ] else
                const Spacer(),
              Row(
                children: [
                  Text(
                    note.isPinned ? 'Disematkan' : 'Catatan',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatRelativeTime(note.updatedAt),
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quick Notes & To-Do List',
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontSize: 27,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<bool>(
                        tooltip: 'Urutkan catatan',
                        initialValue: _sortByTitle,
                        onSelected: (byTitle) {
                          setState(() {
                            _sortByTitle = byTitle;
                            _sortAscending = false;
                          });
                          _refreshNotes(query: _searchController.text);
                        },
                        color: colorScheme.surface,
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: false,
                            child: Text('Baru ditambahkan'),
                          ),
                          PopupMenuItem(
                            value: true,
                            child: Text('Judul (A–Z)'),
                          ),
                        ],
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.tune),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: IconButton(
                          tooltip: isDark
                              ? 'Ganti ke tema terang'
                              : 'Ganti ke tema gelap',
                          onPressed: widget.onToggleTheme,
                          icon: Icon(
                            isDark ? Icons.light_mode : Icons.dark_mode,
                            color: colorScheme.onSurfaceVariant,
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
                      hintText: 'Cari catatan',
                      hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                      prefixIcon: Icon(
                        Icons.search,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              icon: Icon(
                                Icons.close,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                                _refreshNotes();
                              },
                            ),
                      filled: true,
                      fillColor: colorScheme.surface,
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
                        label: 'Semua',
                        count: _showPinnedOnly ? null : _notes.length,
                        selected: !_showPinnedOnly,
                        onTap: () => _setPinnedFilter(false),
                      ),
                      const SizedBox(width: 8),
                      _NoteTab(
                        label: 'Disematkan',
                        selected: _showPinnedOnly,
                        onTap: () => _setPinnedFilter(true),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: _sortAscending
                            ? 'Urutkan dari yang terbaru'
                            : 'Balik urutan',
                        onPressed: () {
                          setState(() => _sortAscending = !_sortAscending);
                          _refreshNotes(query: _searchController.text);
                        },
                        icon: Icon(
                          Icons.sort,
                          color: colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
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
                            ? 'Belum ada catatan yang disematkan.'
                            : 'Catatan tidak ditemukan.',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
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
    final colorScheme = Theme.of(context).colorScheme;
    final color = selected
        ? colorScheme.onPrimary
        : colorScheme.onSurfaceVariant;
    return Material(
      color: selected ? colorScheme.primary : Colors.transparent,
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
