class TechniqueJson {
  TechniqueJson({required this.id, required this.title, required this.subtitle, required this.durationHint, required this.steps});

  final String id;
  final String title;
  final String subtitle;
  final String durationHint;
  final List<String> steps;

  factory TechniqueJson.fromMap(Map<String, Object?> m) => TechniqueJson(
    id: m['id']! as String,
    title: m['title']! as String,
    subtitle: (m['subtitle'] as String?) ?? '',
    durationHint: (m['durationHint'] as String?) ?? '',
    steps: List<String>.from((m['steps'] as List<dynamic>? ?? const []).map((e) => e.toString()), growable: false),
  );
}

class PsychologistTipJson {
  PsychologistTipJson({required this.id, required this.title, required this.category, required this.body});

  final String id;
  final String title;
  final String category;
  final String body;

  factory PsychologistTipJson.fromMap(Map<String, Object?> m) => PsychologistTipJson(
    id: m['id']! as String,
    title: m['title']! as String,
    category: (m['category'] as String?) ?? '',
    body: (m['body'] as String?) ?? '',
  );
}

class QuestJson {
  QuestJson({required this.id, required this.kind, required this.title, required this.body});

  final String id;
  final String kind;
  final String title;
  final String body;

  factory QuestJson.fromMap(Map<String, Object?> m) => QuestJson(
    id: m['id']! as String,
    kind: (m['kind'] as String?) ?? 'daily',
    title: m['title']! as String,
    body: (m['body'] as String?) ?? '',
  );
}

class AchievementJson {
  AchievementJson({required this.id, required this.title, required this.description, required this.icon, required this.rule});

  final String id;
  final String title;
  final String description;
  final String icon;
  final String rule;

  factory AchievementJson.fromMap(Map<String, Object?> m) => AchievementJson(
    id: m['id']! as String,
    title: m['title']! as String,
    description: (m['description'] as String?) ?? '',
    icon: (m['icon'] as String?) ?? 'emoji_events_outlined',
    rule: (m['rule'] as String?) ?? 'custom_rule',
  );
}

class UserProfileRow {
  UserProfileRow({
    required this.displayName,
    required this.course,
    required this.interests,
    this.updatedAt,
  });

  final String displayName;
  final String course;
  final String interests;
  final String? updatedAt;

  factory UserProfileRow.fromMap(Map<String, Object?> m) => UserProfileRow(
    displayName: m['display_name'] as String? ?? '',
    course: m['course'] as String? ?? '',
    interests: m['interests'] as String? ?? '',
    updatedAt: m['updated_at'] as String?,
  );
}

class TaskRow {
  TaskRow({
    required this.id,
    required this.title,
    required this.body,
    required this.kind,
    required this.source,
    required this.isDone,
    this.completedAt,
  });

  final String id;
  final String title;
  final String body;
  final String kind;
  final String source;
  bool isDone;
  String? completedAt;

  factory TaskRow.fromMap(Map<String, Object?> m) => TaskRow(
    id: m['id']! as String,
    title: m['title']! as String,
    body: m['body']! as String,
    kind: m['kind']! as String,
    source: m['source']! as String,
    isDone: (m['is_done'] as int? ?? 0) == 1,
    completedAt: m['completed_at'] as String?,
  );
}

class AchievementRow {
  AchievementRow({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.rule,
    required this.unlocked,
    this.unlockedAt,
  });

  final String id;
  final String title;
  final String description;
  final String icon;
  final String rule;
  bool unlocked;
  String? unlockedAt;

  factory AchievementRow.fromMap(Map<String, Object?> m) => AchievementRow(
    id: m['id']! as String,
    title: m['title']! as String,
    description: m['description']! as String,
    icon: m['icon']! as String,
    rule: m['rule']! as String,
    unlocked: (m['unlocked'] as int? ?? 0) == 1,
    unlockedAt: m['unlocked_at'] as String?,
  );
}

/// Запись `users.json`: анкета Google Forms → скрипт → GitHub Pages; без PIN.
class AllowedUserJson {
  AllowedUserJson({
    required this.id,
    required this.email,
    required this.displayName,
    required this.course,
    required this.interests,
    required this.desiredClub,
    this.legacyLogin = '',
  });

  /// Ключ аккаунта в SQLite (`auth_credentials.login`, совпадает с `PinCrypto.credentialKey`).
  final String id;
  final String email;
  final String displayName;
  final String course;
  final String interests;
  final String desiredClub;
  final String legacyLogin;

  factory AllowedUserJson.fromMap(Map<String, Object?> m) {
    final idRaw = (m['id'] as String? ?? '').trim().toLowerCase();
    final legacy = (m['login'] as String? ?? '').trim().toLowerCase();
    final emailNorm = _normEmail((m['email'] as String? ?? '').trim());
    var resolvedId = idRaw.isNotEmpty ? idRaw : legacy;
    if (resolvedId.isEmpty && emailNorm.isNotEmpty) {
      resolvedId = _fallbackIdFromEmail(emailNorm);
    }
    final displayName = (m['displayName'] as String? ?? '').trim();
    final course = (m['course'] as String? ?? '').trim();
    final interests = _interestsFromMap(m['interests']);
    final desiredClub =
        ((m['desiredClub'] ?? m['club'] ?? m['desired_circle']) as String? ?? '').trim();
    return AllowedUserJson(
      id: resolvedId,
      email: emailNorm,
      displayName: displayName,
      course: course,
      interests: interests,
      desiredClub: desiredClub,
      legacyLogin: legacy,
    );
  }

  static String _normEmail(String s) => s.trim().toLowerCase();

  static String _fallbackIdFromEmail(String normalizedEmail) {
    var h = 0;
    for (final c in normalizedEmail.codeUnits) {
      h = ((h * 131) ^ c) & 0x7fffffff;
    }
    return 'em_${normalizedEmail.hashCode}_${h.toRadixString(16)}';
  }

  static String _interestsFromMap(Object? v) {
    if (v is List) {
      return v.map((e) => e.toString()).where((String s) => s.trim().isNotEmpty).join(', ');
    }
    return (v as String? ?? '').trim();
  }
}
