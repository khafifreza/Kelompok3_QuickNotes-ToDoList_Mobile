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
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? "");
    _contentController = TextEditingController(
      text: widget.note?.content ?? "",
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _saveNote() async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final timestamp = DateTime.now().toIso8601String();

    try {
      if (widget.note == null) {
        final newNote = Note(
          title: title,
          content: content,
          createdAt: timestamp,
        );
        await DBHelper.instance.createNote(newNote);
      } else {
        final updatedNote = Note(
          id: widget.note!.id,
          title: title,
          content: content,
          createdAt: widget.note!.createdAt,
        );
        await DBHelper.instance.updateNote(updatedNote);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Catatan berhasil disimpan')),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal menyimpan: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.note != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Catatan' : 'Tambah Catatan'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveNote),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Judul Catatan / Tugas',
                  border: UnderlineInputBorder(),
                ),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Judul tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TextFormField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    hintText: 'Tulis detail catatan di sini...',
                    border: InputBorder.none,
                  ),
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Isi catatan tidak boleh kosong';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
