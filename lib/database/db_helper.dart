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

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  Future<int> createNote(Note note) async {
    final db = await instance.database;
    return db.insert('notes', note.toMap());
  }

  Future<List<Note>> readAllNotes({String searchQuery = ""}) async {
    final db = await instance.database;
    final result = searchQuery.trim().isEmpty
        ? await db.query('notes', orderBy: 'id DESC')
        : await db.query(
            'notes',
            where: 'title LIKE ?',
            whereArgs: ['%$searchQuery%'],
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
