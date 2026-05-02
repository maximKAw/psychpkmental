import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'schema_migrations.dart';

/// Локальная SQLite: профиль, задания, прогресс, достижения, журнал активности, очередь sync, авторизация (v3).
class AppDatabase {
  AppDatabase._(this._db);

  final Database _db;

  Database get raw => _db;

  static const _dbVersion = 3;

  static Future<AppDatabase> open() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = join(dir.path, 'college_circle_mvp.db');
    final db = await openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
CREATE TABLE user_profile (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  display_name TEXT NOT NULL DEFAULT '',
  course TEXT NOT NULL DEFAULT '',
  interests TEXT NOT NULL DEFAULT '',
  updated_at TEXT NOT NULL DEFAULT ''
);
''');
        await db.execute('''
CREATE TABLE tasks (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  kind TEXT NOT NULL,
  source TEXT NOT NULL DEFAULT 'bundle',
  is_done INTEGER NOT NULL DEFAULT 0,
  completed_at TEXT,
  created_at TEXT NOT NULL
);
''');
        await db.execute('''
CREATE TABLE technique_progress (
  technique_id TEXT PRIMARY KEY,
  practiced_at TEXT,
  practice_count INTEGER NOT NULL DEFAULT 0
);
''');
        await db.execute('''
CREATE TABLE achievements (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  icon TEXT NOT NULL,
  rule TEXT NOT NULL,
  unlocked INTEGER NOT NULL DEFAULT 0,
  unlocked_at TEXT
);
''');
        await db.execute('''
CREATE TABLE activity_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  event TEXT NOT NULL,
  created_at TEXT NOT NULL
);
''');
        await db.execute('''
CREATE TABLE tip_reads (
  tip_id TEXT PRIMARY KEY,
  open_count INTEGER NOT NULL DEFAULT 0,
  last_open_at TEXT
);
''');
        await db.execute('''
CREATE TABLE app_meta (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);
''');
        await createSyncOutboxTable(db);
        await createAuthTables(db);
        await db.insert(
          'auth_session',
          {'id': 1, 'login': '', 'token': '', 'display_name_snap': '', 'updated_at': ''},
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
        await db.insert('user_profile', {'id': 1, 'display_name': '', 'course': '', 'interests': '', 'updated_at': ''});
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await createSyncOutboxTable(db);
        }
        if (oldVersion < 3) {
          await createAuthTables(db);
          await db.insert(
            'auth_session',
            {'id': 1, 'login': '', 'token': '', 'display_name_snap': '', 'updated_at': ''},
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
      },
    );
    return AppDatabase._(db);
  }

  Future<void> close() => _db.close();
}
