import 'package:flutter/material.dart';

import '../../data/models/catalog_models.dart';
import '../../data/repositories/app_repository.dart';
import '../notify/repository_scope.dart';
import 'practice_screen.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  AppRepository? _repo;
  Future<List<TaskRow>>? _tasksFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final r = RepositoryScope.of(context);
    if (_repo != r) {
      _repo?.removeListener(_reloadTasks);
      _repo = r;
      _repo!.addListener(_reloadTasks);
    }
    _tasksFuture ??= _repo!.loadTasks();
  }

  void _reloadTasks() {
    setState(() {
      _tasksFuture = _repo!.loadTasks();
    });
  }

  @override
  void dispose() {
    _repo?.removeListener(_reloadTasks);
    super.dispose();
  }

  Future<void> _taskReflection(BuildContext context, TaskRow t, AppRepository repo) async {
    await showOutboxEnqueueDialog(
      context,
      repo: repo,
      kind: 'task_reflection',
      refId: t.id,
      title: 'Заметка к заданию',
      subtitle: t.title,
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    final theme = Theme.of(context);

    return FutureBuilder<List<TaskRow>>(
      future: _tasksFuture,
      builder: (context, snapshot) {
        final tasks = snapshot.data;
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Колледж‑круг',
                style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 4),
              Text('Сегодня', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Задания и квесты',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Подтянуть каталог JSON (GitHub Pages)',
                            onPressed: () async {
                              await repo.trySyncRemoteCatalog();
                              if (context.mounted) {
                                _reloadTasks();
                              }
                            },
                            icon: const Icon(Icons.cloud_download_rounded),
                          ),
                        ],
                      ),
                      if (repo.lastRemoteError != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Сеть: ${repo.lastRemoteError}',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                        ),
                      ],
                      const SizedBox(height: 8),
                      if (tasks == null)
                        const Padding(
                          padding: EdgeInsets.all(28),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (tasks.isEmpty)
                        Text('Нет заданий в базе.', style: theme.textTheme.bodyMedium)
                      else
                        Column(
                          children: tasks.map((t) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Checkbox(
                                        value: t.isDone,
                                        onChanged: (v) => repo.setTaskDone(t.id, v ?? false),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.only(top: 12, bottom: 8),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(t.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                                              const SizedBox(height: 8),
                                              Text(t.body, style: theme.textTheme.bodyMedium?.copyWith(height: 1.35)),
                                              const SizedBox(height: 10),
                                              Text(
                                                t.kind == 'quest' ? 'Тип: квест' : 'Тип: ежедневное',
                                                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Заметка / ответ в очередь',
                                        icon: Icon(Icons.edit_note_rounded, color: theme.colorScheme.primary),
                                        onPressed: () => _taskReflection(context, t, repo),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'SQLite v2 хранит прогресс и офлайн-очередь ответов. Каталог заданий — JSON на Pages.',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        );
      },
    );
  }
}
