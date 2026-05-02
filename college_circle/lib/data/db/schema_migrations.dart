import 'package:sqflite/sqflite.dart';

Future<void> createSyncOutboxTable(DatabaseExecutor db) async {
  await db.execute('''
CREATE TABLE IF NOT EXISTS sync_outbox (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  kind TEXT NOT NULL,
  ref_id TEXT,
  body TEXT NOT NULL,
  meta_json TEXT,
  created_at TEXT NOT NULL,
  synced INTEGER NOT NULL DEFAULT 0,
  attempts INTEGER NOT NULL DEFAULT 0,
  last_error TEXT
);
''');
  await db.execute('''
CREATE INDEX IF NOT EXISTS idx_outbox_pending ON sync_outbox (synced, created_at DESC);
''');
}

/// Таблицы локальной авторизации v3 (сессия + хэш PIN). Пароли не хранятся в JSON Pages.
Future<void> createAuthTables(DatabaseExecutor db) async {
  await db.execute('''
CREATE TABLE IF NOT EXISTS auth_session (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  login TEXT NOT NULL DEFAULT '',
  token TEXT NOT NULL DEFAULT '',
  display_name_snap TEXT NOT NULL DEFAULT '',
  updated_at TEXT NOT NULL DEFAULT ''
);
''');
  await db.execute('''
CREATE TABLE IF NOT EXISTS auth_credentials (
  login TEXT PRIMARY KEY,
  pin_hash TEXT NOT NULL,
  salt TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
''');
}
