import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

Database? _db;

Future<Database> openNotesDb() async {
  if (_db != null) return _db!;
  final path = join(await getDatabasesPath(), 'notes.db');
  _db = await openDatabase(
    path,
    version: 1,
    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE notes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          body TEXT NOT NULL DEFAULT '',
          updated_at TEXT NOT NULL,
          dirty INTEGER NOT NULL DEFAULT 0
        )
      ''');
    },
  );
  return _db!;
}