import 'package:flutter/material.dart';

import '../database/db_helper.dart';
import '../models/note_model.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note? note;

  const NoteEditorScreen({super.key, this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  static const _accent = Color(0xFF32866A);

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late bool _isPinned;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(
      text: widget.note?.content ?? '',
    );
    _isPinned = widget.note?.isPinned ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final timestamp = DateTime.now().toIso8601String();

    try {
      if (widget.note == null) {
        await DBHelper.instance.createNote(
          Note(
            title: title,
            content: content,
            createdAt: timestamp,
            updatedAt: timestamp,
            isPinned: _isPinned,
          ),
        );
      } else {
        await DBHelper.instance.updateNote(
          Note(
            id: widget.note!.id,
            title: title,
            content: content,
            createdAt: widget.note!.createdAt,
            updatedAt: timestamp,
            isPinned: _isPinned,
          ),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Catatan tersimpan')));
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan catatan: $error')),
      );
    }
  }

  Future<void> _deleteNote() async {
    final note = widget.note;
    if (note?.id == null) return;
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
    await DBHelper.instance.deleteNote(note!.id!);
    if (!mounted) return;
    Navigator.pop(context);
  }

  String _formatCreatedAt(BuildContext context) {
    final date = DateTime.tryParse(widget.note?.createdAt ?? '');
    if (date == null) return '';
    final localizations = MaterialLocalizations.of(context);
    return '${localizations.formatMediumDate(date)} · '
        '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(date))}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.onSurface,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    icon: const Icon(Icons.chevron_left, size: 22),
                    label: const Text('Catatan'),
                  ),
                  const Spacer(),
                  if (widget.note != null)
                    PopupMenuButton<String>(
                      tooltip: 'Aksi catatan lainnya',
                      color: colorScheme.surface,
                      onSelected: (action) {
                        if (action == 'delete') _deleteNote();
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Hapus catatan'),
                        ),
                      ],
                    ),
                  TextButton(
                    onPressed: _saveNote,
                    style: TextButton.styleFrom(
                      foregroundColor: _accent,
                      textStyle: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Selesai'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 32),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _formatCreatedAt(context),
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: _isPinned
                              ? 'Lepas sematan catatan'
                              : 'Sematkan catatan',
                          onPressed: () =>
                              setState(() => _isPinned = !_isPinned),
                          icon: Icon(
                            _isPinned
                                ? Icons.push_pin
                                : Icons.push_pin_outlined,
                            color: _isPinned
                                ? _accent
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    TextFormField(
                      controller: _titleController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Judul',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 32,
                        height: 1.15,
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.7,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Judul tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _contentController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Tulis catatan...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 16,
                        height: 1.6,
                      ),
                      minLines: 8,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Isi catatan tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
