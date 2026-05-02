// Запись офлайн-очереди пользовательских ответов перед отправкой на бэкенд.

class OutboxRow {
  const OutboxRow({
    required this.id,
    required this.kind,
    this.refId,
    required this.body,
    this.metaJson,
    required this.createdAt,
    required this.synced,
    required this.attempts,
    this.lastError,
  });

  final int id;
  final String kind;
  final String? refId;
  final String body;
  final String? metaJson;
  final String createdAt;
  final bool synced;
  final int attempts;
  final String? lastError;

  factory OutboxRow.fromMap(Map<String, Object?> m) => OutboxRow(
    id: m['id']! as int,
    kind: m['kind']! as String,
    refId: m['ref_id'] as String?,
    body: m['body']! as String,
    metaJson: m['meta_json'] as String?,
    createdAt: m['created_at']! as String,
    synced: (m['synced'] as int? ?? 0) == 1,
    attempts: m['attempts'] as int? ?? 0,
    lastError: m['last_error'] as String?,
  );
}

class OutboxSyncResult {
  OutboxSyncResult({required this.postedCount, required this.skippedBecauseNoUrl, this.error});

  /// Сколько записей отправлено HTTP-пакетами (обычно 1 POST на весь блок).
  final int postedCount;
  final bool skippedBecauseNoUrl;
  final String? error;

  bool get hasError => error != null && error!.isNotEmpty;
}
