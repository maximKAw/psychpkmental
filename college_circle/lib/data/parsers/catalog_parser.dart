import 'dart:convert';

import '../models/catalog_models.dart';

class CatalogParser {
  static List<TechniqueJson> parseTechniques(String raw) {
    final map = jsonDecode(raw) as Map<String, Object?>;
    final list = map['items']! as List<dynamic>;
    return list.map((e) => TechniqueJson.fromMap(Map<String, Object?>.from(e as Map))).toList();
  }

  static List<PsychologistTipJson> parseTips(String raw) {
    final map = jsonDecode(raw) as Map<String, Object?>;
    final list = map['items']! as List<dynamic>;
    return list.map((e) => PsychologistTipJson.fromMap(Map<String, Object?>.from(e as Map))).toList();
  }

  static List<QuestJson> parseQuests(String raw) {
    final map = jsonDecode(raw) as Map<String, Object?>;
    final list = map['items']! as List<dynamic>;
    return list.map((e) => QuestJson.fromMap(Map<String, Object?>.from(e as Map))).toList();
  }

  static List<AchievementJson> parseAchievements(String raw) {
    final map = jsonDecode(raw) as Map<String, Object?>;
    final list = map['items']! as List<dynamic>;
    return list.map((e) => AchievementJson.fromMap(Map<String, Object?>.from(e as Map))).toList();
  }

  static List<AllowedUserJson> parseAllowedUsers(String raw) {
    final map = jsonDecode(raw) as Map<String, Object?>;
    final list = map['items']! as List<dynamic>;
    return list.map((e) => AllowedUserJson.fromMap(Map<String, Object?>.from(e as Map))).where((u) => u.id.isNotEmpty).toList();
  }

  /// Удалённые записи с тем же `id` перекрывают локальные; новые id из remote дописываются.
  static List<TechniqueJson> mergeTechniques(List<TechniqueJson> local, List<TechniqueJson> remote) =>
      _mergeOverlay(local, remote, (t) => t.id);

  static List<PsychologistTipJson> mergeTips(List<PsychologistTipJson> local, List<PsychologistTipJson> remote) =>
      _mergeOverlay(local, remote, (t) => t.id);

  static List<QuestJson> mergeQuests(List<QuestJson> local, List<QuestJson> remote) =>
      _mergeOverlay(local, remote, (t) => t.id);

  static List<AchievementJson> mergeAchievements(List<AchievementJson> local, List<AchievementJson> remote) =>
      _mergeOverlay(local, remote, (t) => t.id);

  /// Удалённые записи с тем же `id` перекрывают локальные.
  static List<AllowedUserJson> mergeAllowedUsers(List<AllowedUserJson> local, List<AllowedUserJson> remote) =>
      _mergeOverlay(local, remote, (u) => u.id);

  static List<T> _mergeOverlay<T>(List<T> local, List<T> remote, String Function(T) idOf) {
    final remoteMap = {for (final r in remote) idOf(r): r};
    final placed = <String>{};
    final out = <T>[];
    for (final l in local) {
      final id = idOf(l);
      placed.add(id);
      out.add(remoteMap[id] ?? l);
    }
    for (final r in remote) {
      final id = idOf(r);
      if (!placed.contains(id)) {
        placed.add(id);
        out.add(r);
      }
    }
    return out;
  }
}
