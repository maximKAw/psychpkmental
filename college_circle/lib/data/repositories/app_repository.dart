import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';

import '../../config/app_config.dart';
import '../../services/pin_crypto.dart';
import '../db/app_database.dart';
import '../models/catalog_models.dart';
import '../models/outbox_models.dart';
import '../parsers/catalog_parser.dart';

const _assetTechniques = 'assets/data/techniques.json';
const _assetTips = 'assets/data/psychologist_tips.json';
const _assetQuests = 'assets/data/quests.json';
const _assetAchievements = 'assets/data/achievements.json';
const _assetUsers = 'assets/data/users.json';

const _tokenAlphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';

/// Каталог контента + операции SQLite. Уведомляет слушателей после изменений прогресса.
class AppRepository extends ChangeNotifier {
  AppRepository(this._appDb);

  final AppDatabase _appDb;

  Database get _db => _appDb.raw;

  List<TechniqueJson> techniques = [];
  List<PsychologistTipJson> tips = [];
  List<AchievementJson> achievementCatalog = [];
  List<QuestJson> questsCatalog = [];
  List<AllowedUserJson> allowedUsers = [];

  /// Стабильный `id` из roster (SQLite: `auth_session.login` как «ключ сессии»).
  String _sessionUserId = '';
  String _authDisplaySnap = '';

  String? _lastRemoteError;

  String? get lastRemoteError => _lastRemoteError;

  bool get isAuthenticated => _sessionUserId.trim().isNotEmpty;

  /// Совместимость: ключ учётной записи = roster `id`.
  String get sessionLogin => sessionUserId;

  String get sessionUserId => _sessionUserId;

  AllowedUserJson? get sessionRosterEntry {
    final key = _sessionUserId.trim();
    if (key.isEmpty) {
      return null;
    }
    for (final u in allowedUsers) {
      if (u.id == key) {
        return u;
      }
    }
    return null;
  }

  String get sessionBannerName {
    final u = sessionRosterEntry;
    if (u != null && u.displayName.isNotEmpty) {
      return u.displayName;
    }
    if (_authDisplaySnap.isNotEmpty) {
      return _authDisplaySnap;
    }
    return _sessionUserId;
  }

  String get sessionAccountSubtitle {
    final u = sessionRosterEntry;
    if (u != null && u.email.isNotEmpty) {
      return u.email;
    }
    return _sessionUserId;
  }

  /// Вход по **email** (если есть `@`) или по **полному имени** / устаревшему **`login`** / **`id`**.
  AllowedUserJson? resolveUserForSignIn(String rawInput) {
    final t = rawInput.trim();
    if (t.isEmpty) {
      return null;
    }
    if (t.contains('@')) {
      final e = _normalizeSignInEmail(t);
      AllowedUserJson? hit;
      for (final u in allowedUsers) {
        if (u.email.isEmpty) {
          continue;
        }
        if (u.email == e) {
          if (hit != null && hit.id != u.id) {
            throw ArgumentError('В списке несколько строк с одним email — поправьте таблицу или users.json.');
          }
          hit = u;
        }
      }
      return hit;
    }
    final tl = t.toLowerCase();
    for (final u in allowedUsers) {
      if (u.id == tl || (u.legacyLogin.isNotEmpty && u.legacyLogin == tl)) {
        return u;
      }
    }
    final target = _collapseSpacesLower(t);
    final byName = allowedUsers
        .where((u) => u.displayName.trim().isNotEmpty && _collapseSpacesLower(u.displayName) == target)
        .toList();
    if (byName.isEmpty) {
      return null;
    }
    if (byName.length > 1) {
      throw ArgumentError('Несколько людей с таким именем — войдите по email из анкеты.');
    }
    return byName.first;
  }

  static String _normalizeSignInEmail(String s) => s.trim().toLowerCase();

  static String _collapseSpacesLower(String s) =>
      s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  Future<void> initialize() async {
    _lastRemoteError = null;
    final tRaw = await rootBundle.loadString(_assetTechniques);
    final pRaw = await rootBundle.loadString(_assetTips);
    final qRaw = await rootBundle.loadString(_assetQuests);
    final aRaw = await rootBundle.loadString(_assetAchievements);
    final uRaw = await rootBundle.loadString(_assetUsers);

    techniques = CatalogParser.parseTechniques(tRaw);
    tips = CatalogParser.parseTips(pRaw);
    questsCatalog = CatalogParser.parseQuests(qRaw);
    achievementCatalog = CatalogParser.parseAchievements(aRaw);
    allowedUsers = CatalogParser.parseAllowedUsers(uRaw);

    await _seedAchievementsIfNeeded();
    await _seedTasksFromCatalog();
    await refreshAchievementState();
    await _restoreAuthSession();
    notifyListeners();
    // ignore: discarded_futures
    trySyncRemoteCatalog();
  }

  Future<void> trySyncRemoteCatalog() async {
    if (!hasRemoteCatalog) {
      return;
    }
    _lastRemoteError = null;
    try {
      final t = await _fetchJson('techniques.json');
      final p = await _fetchJson('psychologist_tips.json');
      final q = await _fetchJson('quests.json');
      final a = await _fetchJson('achievements.json');

      if (t != null) {
        final remote = CatalogParser.parseTechniques(t);
        techniques = CatalogParser.mergeTechniques(techniques, remote);
      }
      if (p != null) {
        final remote = CatalogParser.parseTips(p);
        tips = CatalogParser.mergeTips(tips, remote);
      }
      if (q != null) {
        final remote = CatalogParser.parseQuests(q);
        questsCatalog = CatalogParser.mergeQuests(questsCatalog, remote);
        await _upsertTasksFromRemoteCatalog();
      }
      if (a != null) {
        final remote = CatalogParser.parseAchievements(a);
        achievementCatalog = CatalogParser.mergeAchievements(achievementCatalog, remote);
        await _seedAchievementsIfNeeded();
      }
      final u = await _fetchJson('users.json');
      if (u != null) {
        final remote = CatalogParser.parseAllowedUsers(u);
        allowedUsers = CatalogParser.mergeAllowedUsers(allowedUsers, remote);
      }
      await refreshAchievementState();
      notifyListeners();
    } catch (e) {
      _lastRemoteError = e.toString();
      notifyListeners();
    }
  }

  Future<String?> _fetchJson(String name) async {
    final uri = Uri.parse(remoteUrl(name));
    final res = await http.get(uri).timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) {
      return null;
    }
    return res.body;
  }

  Future<void> _seedAchievementsIfNeeded() async {
    final batch = _db.batch();
    for (final a in achievementCatalog) {
      batch.insert('achievements', {
        'id': a.id,
        'title': a.title,
        'description': a.description,
        'icon': a.icon,
        'rule': a.rule,
        'unlocked': 0,
        'unlocked_at': null,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
  }

  Future<void> _seedTasksFromCatalog() async {
    final now = DateTime.now().toIso8601String();
    final batch = _db.batch();
    for (final q in questsCatalog) {
      batch.insert('tasks', {
        'id': q.id,
        'title': q.title,
        'body': q.body,
        'kind': q.kind,
        'source': 'bundle',
        'is_done': 0,
        'completed_at': null,
        'created_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
  }

  Future<void> _upsertTasksFromRemoteCatalog() async {
    final now = DateTime.now().toIso8601String();
    final batch = _db.batch();
    for (final q in questsCatalog) {
      batch.insert('tasks', {
        'id': q.id,
        'title': q.title,
        'body': q.body,
        'kind': q.kind,
        'source': 'remote',
        'is_done': 0,
        'completed_at': null,
        'created_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
  }

  Future<UserProfileRow> loadProfile() async {
    final rows = await _db.query('user_profile', where: 'id = ?', whereArgs: [1], limit: 1);
    return UserProfileRow.fromMap(rows.single);
  }

  Future<void> saveProfile({required String displayName, required String course, required String interests}) async {
    final now = DateTime.now().toIso8601String();
    await _db.update(
      'user_profile',
      {'display_name': displayName, 'course': course, 'interests': interests, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [1],
    );
    await enqueueOutbox(
      kind: 'profile_snapshot',
      body: jsonEncode(<String, Object?>{
        'display_name': displayName,
        'course': course,
        'interests': interests,
        'saved_at': now,
      }),
      meta: const {'hint': 'снимок для последующей синхронизации с сервером'},
    );
    await refreshAchievementState();
    notifyListeners();
  }

  Future<List<TaskRow>> loadTasks() async {
    final maps = await _db.query('tasks', orderBy: 'kind DESC, id ASC');
    return maps.map(TaskRow.fromMap).toList();
  }

  Future<void> setTaskDone(String id, bool done) async {
    final now = DateTime.now().toIso8601String();
    await _db.update(
      'tasks',
      {'is_done': done ? 1 : 0, 'completed_at': done ? now : null},
      where: 'id = ?',
      whereArgs: [id],
    );
    await refreshAchievementState();
    notifyListeners();
  }

  Future<void> markTechniquePracticed(String techniqueId) async {
    final now = DateTime.now().toIso8601String();
    final prevRows = await _db.query(
      'technique_progress',
      columns: ['practice_count'],
      where: 'technique_id = ?',
      whereArgs: [techniqueId],
      limit: 1,
    );
    final prev = prevRows.isEmpty ? 0 : (prevRows.first['practice_count'] as int? ?? 0);
    await _db.insert('technique_progress', {
      'technique_id': techniqueId,
      'practiced_at': now,
      'practice_count': prev + 1,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    await refreshAchievementState();
    notifyListeners();
  }

  Future<void> logActivity(String event) async {
    final now = DateTime.now().toIso8601String();
    await _db.insert('activity_log', {'event': event, 'created_at': now});
    await refreshAchievementState();
    notifyListeners();
  }

  Future<void> registerTipOpened(String tipId) async {
    final now = DateTime.now().toIso8601String();
    final prevRows =
        await _db.query(
          'tip_reads',
          columns: ['open_count'],
          where: 'tip_id = ?',
          whereArgs: [tipId],
          limit: 1,
        );
    final prev = prevRows.isEmpty ? 0 : (prevRows.first['open_count'] as int? ?? 0);
    await _db.insert(
      'tip_reads',
      {'tip_id': tipId, 'open_count': prev + 1, 'last_open_at': now},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await refreshAchievementState();
    notifyListeners();
  }

  Future<int> countDistinctTipsOpened() async {
    final rows = await _db.rawQuery('SELECT COUNT(*) AS c FROM tip_reads WHERE open_count > 0');
    final c = rows.first['c'] as int? ?? 0;
    return c;
  }

  Future<bool> hasActivity(String event) async {
    final rows = await _db.query('activity_log', where: 'event = ?', whereArgs: [event], limit: 1);
    return rows.isNotEmpty;
  }

  Future<List<AchievementRow>> loadAchievements() async {
    final maps = await _db.query('achievements', orderBy: 'id ASC');
    return maps.map(AchievementRow.fromMap).toList();
  }

  /// Пересчитывает флаги разблокировки по правилам из каталога.
  Future<void> refreshAchievementState() async {
    final profile = await loadProfile();
    final tipsOpened = await countDistinctTipsOpened();
    final hasTechnique = await _db.query('technique_progress', limit: 1);
    final tasksDone =
        Sqflite.firstIntValue(
          await _db.rawQuery('SELECT COUNT(*) FROM tasks WHERE is_done = 1'),
        ) ??
        0;

    Future<void> unlockIf(String rule, bool condition) async {
      if (!condition) {
        return;
      }
      final now = DateTime.now().toIso8601String();
      await _db.rawUpdate(
        'UPDATE achievements SET unlocked = 1, unlocked_at = COALESCE(unlocked_at, ?) WHERE rule = ? AND unlocked = 0',
        [now, rule],
      );
    }

    await unlockIf('profile_saved', profile.displayName.trim().isNotEmpty);
    await unlockIf('technique_practiced', hasTechnique.isNotEmpty);
    await unlockIf('tips_opened_3', tipsOpened >= 3);
    await unlockIf('task_done', tasksDone >= 1);
    await unlockIf('breathing_done', await hasActivity('breathing_complete'));
    await unlockIf('memory_done', await hasActivity('memory_complete'));
    await unlockIf('colors_done', await hasActivity('colors_complete'));
    await unlockIf('ripple_done', await hasActivity('ripple_complete'));
    await unlockIf('word_scr_done', await hasActivity('word_scr_complete'));
    await unlockIf('pattern_soft_done', await hasActivity('pattern_soft_complete'));
    await unlockIf('gratitude_three_done', await hasActivity('gratitude_three_complete'));
  }

  // ——— Авторизация v3: whitelist из JSON Pages, PIN только в SQLite ———

  String _newSessionToken() {
    final r = Random.secure();
    return List.generate(24, (_) => _tokenAlphabet[r.nextInt(_tokenAlphabet.length)]).join();
  }

  Future<void> _restoreAuthSession() async {
    final rows = await _db.query('auth_session', where: 'id = ?', whereArgs: const [1], limit: 1);
    if (rows.isEmpty) {
      _sessionUserId = '';
      _authDisplaySnap = '';
      return;
    }
    _sessionUserId = (rows.first['login'] as String? ?? '').trim();
    _authDisplaySnap = (rows.first['display_name_snap'] as String? ?? '').trim();
  }

  Future<void> _persistSession({required String userCredentialId, required String displaySnap}) async {
    final token = _newSessionToken();
    final now = DateTime.now().toIso8601String();
    await _db.insert(
      'auth_session',
      {
        'id': 1,
        'login': userCredentialId,
        'token': token,
        'display_name_snap': displaySnap,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _sessionUserId = userCredentialId;
    _authDisplaySnap = displaySnap;
  }

  Future<bool> credentialExistsForUserId(String userCredentialId) async {
    final id = userCredentialId.trim().toLowerCase();
    if (id.isEmpty) {
      return false;
    }
    final rows = await _db.query('auth_credentials', where: 'login = ?', whereArgs: [id], limit: 1);
    return rows.isNotEmpty;
  }

  Future<void> loginWithPinForUser(AllowedUserJson rosterUser, String pin) async {
    final key = rosterUser.id;
    final norm = PinCrypto.normalizeDigits(pin);
    if (norm == null) {
      throw ArgumentError('PIN: только цифры, не короче 4.');
    }
    final rows = await _db.query('auth_credentials', where: 'login = ?', whereArgs: [key], limit: 1);
    if (rows.isEmpty) {
      throw StateError('На этом устройстве PIN ещё не задан — введите PIN дважды при первом входе.');
    }
    final salt = rows.first['salt']! as String;
    final hash = rows.first['pin_hash']! as String;
    final ok =
        PinCrypto.hashPin(saltHex: salt, credentialKey: key, normalizedPin: norm) == hash;
    if (!ok) {
      throw ArgumentError('Неверный PIN.');
    }
    await _persistSession(userCredentialId: key, displaySnap: rosterUser.displayName);
    notifyListeners();
  }

  Future<void> enrollAndLoginUser(AllowedUserJson rosterUser, String pin, String pinAgain) async {
    final key = rosterUser.id;
    final p1 = PinCrypto.normalizeDigits(pin);
    final p2 = PinCrypto.normalizeDigits(pinAgain);
    if (p1 == null || p2 == null || p1 != p2) {
      throw ArgumentError('PIN должны совпадать и состоять из цифр (≥4).');
    }
    final salt = PinCrypto.generateSaltHex();
    final hash = PinCrypto.hashPin(saltHex: salt, credentialKey: key, normalizedPin: p1);
    final now = DateTime.now().toIso8601String();
    await _db.insert(
      'auth_credentials',
      {'login': key, 'pin_hash': hash, 'salt': salt, 'updated_at': now},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _persistSession(userCredentialId: key, displaySnap: rosterUser.displayName);
    notifyListeners();
  }

  Future<void> logout() async {
    final now = DateTime.now().toIso8601String();
    await _db.update(
      'auth_session',
      {'login': '', 'token': '', 'display_name_snap': '', 'updated_at': now},
      where: 'id = ?',
      whereArgs: const [1],
    );
    _sessionUserId = '';
    _authDisplaySnap = '';
    notifyListeners();
  }

  // ——— Офлайн-очередь пользовательских ответов (миграция v2: sync_outbox) ———

  Future<void> enqueueOutbox({required String kind, String? refId, required String body, Map<String, Object?>? meta}) async {
    final now = DateTime.now().toIso8601String();
    final metaStr = meta == null ? null : jsonEncode(meta);
    await _db.insert('sync_outbox', {
      'kind': kind,
      'ref_id': refId,
      'body': body,
      'meta_json': metaStr,
      'created_at': now,
      'synced': 0,
      'attempts': 0,
      'last_error': null,
    });
    notifyListeners();
  }

  Future<List<OutboxRow>> loadOutbox({bool pendingOnly = true}) async {
    final maps = pendingOnly
        ? await _db.query('sync_outbox', where: 'synced = ?', whereArgs: [0], orderBy: 'created_at DESC')
        : await _db.query('sync_outbox', orderBy: 'created_at DESC', limit: 200);
    return maps.map(OutboxRow.fromMap).toList();
  }

  Future<int> pendingOutboxCount() async =>
      Sqflite.firstIntValue(await _db.rawQuery('SELECT COUNT(*) FROM sync_outbox WHERE synced = 0')) ?? 0;

  Future<void> markOutboxRowsSynced(Set<int> ids) async {
    if (ids.isEmpty) {
      return;
    }
    final batch = _db.batch();
    for (final id in ids) {
      batch.update('sync_outbox', {'synced': 1, 'last_error': null}, where: 'id = ?', whereArgs: [id]);
    }
    await batch.commit(noResult: true);
    notifyListeners();
  }

  Future<void> _incrementOutboxAttempt(int id, String err) async {
    await _db.rawUpdate(
      'UPDATE sync_outbox SET attempts = attempts + 1, last_error = ? WHERE id = ?',
      [err.length > 500 ? '${err.substring(0, 500)}…' : err, id],
    );
  }

  /// POST всех висящих записей на [kOutboxIngestUrl]; при успехе помечает их `synced`.
  Future<OutboxSyncResult> syncPendingOutboxViaHttp() async {
    if (!hasOutboxIngestUrl) {
      return OutboxSyncResult(postedCount: 0, skippedBecauseNoUrl: true);
    }
    final pending = await loadOutbox(pendingOnly: true);
    if (pending.isEmpty) {
      return OutboxSyncResult(postedCount: 0, skippedBecauseNoUrl: false);
    }
    final uri = Uri.parse(kOutboxIngestUrl.trim());
    final entries = pending
        .map(
          (e) => <String, Object?>{
            'local_id': e.id,
            'kind': e.kind,
            'ref_id': e.refId,
            'body': e.body,
            'meta': e.metaJson == null ? null : jsonDecode(e.metaJson!),
            'created_at': e.createdAt,
          },
        )
        .toList(growable: false);
    final payload = <String, Object?>{
      'exported_at': DateTime.now().toIso8601String(),
      'app': 'college_circle_mvp',
      'entries': entries,
    };
    try {
      final res = await http
          .post(uri, headers: {'Content-Type': 'application/json; charset=utf-8'}, body: jsonEncode(payload))
          .timeout(const Duration(seconds: 25));
      if (res.statusCode < 200 || res.statusCode >= 300) {
        final snippet = res.body.length > 240 ? '${res.body.substring(0, 240)}…' : res.body;
        for (final p in pending) {
          await _incrementOutboxAttempt(p.id, 'HTTP ${res.statusCode}: $snippet');
        }
        notifyListeners();
        return OutboxSyncResult(postedCount: 0, skippedBecauseNoUrl: false, error: 'HTTP ${res.statusCode}');
      }
      await markOutboxRowsSynced(pending.map((e) => e.id).toSet());
      await logActivity('outbox_upload_ok');
      return OutboxSyncResult(postedCount: pending.length, skippedBecauseNoUrl: false);
    } catch (e) {
      for (final p in pending) {
        await _incrementOutboxAttempt(p.id, e.toString());
      }
      notifyListeners();
      return OutboxSyncResult(postedCount: 0, skippedBecauseNoUrl: false, error: e.toString());
    }
  }

  /// Когда свой сервер ещё нет — «ручное» признание, что записи уже не нужно слать постом MVP.
  Future<void> clearPendingOutboxMarkedSynced() async {
    await _db.rawUpdate('UPDATE sync_outbox SET synced = 1, last_error = NULL WHERE synced = 0');
    notifyListeners();
  }

  Future<void> deleteOutboxEntry(int id) async {
    await _db.delete('sync_outbox', where: 'id = ?', whereArgs: [id]);
    notifyListeners();
  }
}
