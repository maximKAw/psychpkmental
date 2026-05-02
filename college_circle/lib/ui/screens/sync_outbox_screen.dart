import 'package:flutter/material.dart';

import '../../data/models/outbox_models.dart';
import '../../data/repositories/app_repository.dart';
import '../notify/repository_scope.dart';

class SyncOutboxScreen extends StatefulWidget {
  const SyncOutboxScreen({super.key});

  @override
  State<SyncOutboxScreen> createState() => _SyncOutboxScreenState();
}

class _SyncOutboxScreenState extends State<SyncOutboxScreen> {
  bool _pendingOnly = true;

  AppRepository get _repo => RepositoryScope.of(context);

  Future<void> _syncHttp() async {
    final msg = ScaffoldMessenger.maybeOf(context);
    final result = await _repo.syncPendingOutboxViaHttp();
    if (!mounted) {
      return;
    }
    if (result.skippedBecauseNoUrl) {
      msg?.showSnackBar(
        const SnackBar(
          content: Text('Не задан URL приёма: --dart-define=OUTBOX_INGEST_URL=https://…'),
        ),
      );
      return;
    }
    if (result.hasError) {
      msg?.showSnackBar(SnackBar(content: Text('Ошибка: ${result.error}')));
      return;
    }
    if (result.postedCount > 0) {
      msg?.showSnackBar(SnackBar(content: Text('Отправлено записей: ${result.postedCount}')));
    } else {
      msg?.showSnackBar(const SnackBar(content: Text('Неотправленных записей нет.')));
    }
    setState(() {});
  }

  Future<void> _confirmMarkSyncedLocally() async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Пометить как отправленные?'),
        content: const Text(
          'Без HTTP локальная очередь считается доставленной. Удобно после ручной передачи куратору или для занятий без сервера.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Да')),
        ],
      ),
    );
    if (ok == true) {
      await _repo.clearPendingOutboxMarkedSynced();
      messenger?.showSnackBar(const SnackBar(content: Text('Помечено как отправлено локально')));
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Очередь ответов')),
      body: Column(
        children: [
          SwitchListTile(
            title: const Text('Только неотправленные'),
            subtitle: Text('История сохранена в базе последних 200 записей', style: theme.textTheme.bodySmall),
            value: _pendingOnly,
            onChanged: (v) => setState(() => _pendingOnly = v),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton.icon(onPressed: _syncHttp, icon: const Icon(Icons.upload_rounded), label: const Text('POST на сервер')),
                OutlinedButton(onPressed: _confirmMarkSyncedLocally, child: const Text('Убрать без HTTP')),
              ],
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: _repo,
              builder: (context, _) {
                return FutureBuilder<List<OutboxRow>>(
                  future: _repo.loadOutbox(pendingOnly: _pendingOnly),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final rows = snapshot.data!;
                    if (rows.isEmpty) {
                      return Center(
                        child: Text(
                          _pendingOnly ? 'Нет необработанных ответов — отличная работа!' : 'Нет записей в истории',
                          style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: rows.length,
                      itemBuilder: (context, index) {
                        final r = rows[index];
                        return Card(
                          child: ListTile(
                            leading: Icon(
                              r.synced ? Icons.task_alt_rounded : Icons.hourglass_bottom_rounded,
                              color: r.synced ? theme.colorScheme.tertiary : theme.colorScheme.primary,
                            ),
                            title: Text(r.kind),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (r.refId != null)
                                    Text(
                                      'ref: ${r.refId}',
                                      style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                    ),
                                  Text(
                                    r.body.length > 280 ? '${r.body.substring(0, 280)}…' : r.body,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  if (r.attempts > 0 || (r.lastError != null && r.lastError!.isNotEmpty))
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        'Попыток: ${r.attempts}'
                                        '${r.lastError != null ? ' · ${r.lastError}' : ''}',
                                        style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.error),
                                      ),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(r.createdAt, style: theme.textTheme.labelSmall),
                                  ),
                                ],
                              ),
                            ),
                            isThreeLine: true,
                            trailing: (!r.synced)
                                ? IconButton(
                                    tooltip: 'Удалить',
                                    icon: const Icon(Icons.delete_outline_rounded),
                                    onPressed: () async {
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Удалить строку очереди?'),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Нет')),
                                            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Да')),
                                          ],
                                        ),
                                      );
                                      if (confirmed == true) {
                                        await _repo.deleteOutboxEntry(r.id);
                                        if (context.mounted) {
                                          setState(() {});
                                        }
                                      }
                                    },
                                  )
                                : null,
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
