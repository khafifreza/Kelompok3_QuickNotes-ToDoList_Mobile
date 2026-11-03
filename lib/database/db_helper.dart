import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/note_model.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;

  DBHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('notes.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        isPinned INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE notes ADD COLUMN isPinned INTEGER NOT NULL DEFAULT 0',
      );
    }
    if (oldVersion < 3) {
      await db.execute(
        "ALTER TABLE notes ADD COLUMN updatedAt TEXT NOT NULL DEFAULT ''",
      );
      await db.execute(
        'UPDATE notes SET updatedAt = createdAt WHERE updatedAt = ?',
        [''],
      );
    }
  }

  Future<int> createNote(Note note) async {
    final db = await instance.database;
    return db.insert('notes', note.toMap());
  }

  Future<List<Note>> readAllNotes({
    String searchQuery = "",
    bool pinnedOnly = false,
  }) async {
    final db = await instance.database;
    final conditions = <String>[];
    final whereArgs = <Object>[];
    if (searchQuery.trim().isNotEmpty) {
      conditions.add('title LIKE ?');
      whereArgs.add('%${searchQuery.trim()}%');
    }
    if (pinnedOnly) {
      conditions.add('isPinned = ?');
      whereArgs.add(1);
    }
    final result = await db.query(
      'notes',
      where: conditions.isEmpty ? null : conditions.join(' AND '),
      whereArgs: conditions.isEmpty ? null : whereArgs,
      orderBy: 'id DESC',
    );
    return result.map((json) => Note.fromMap(json)).toList();
  }

  Future<int> updateNote(Note note) async {
    final db = await instance.database;
    return db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<int> deleteNote(int id) async {
    final db = await instance.database;
    return db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }
}
