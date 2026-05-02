import 'package:flutter/material.dart';

import '../../data/models/catalog_models.dart';
import '../../data/repositories/app_repository.dart';
import '../notify/repository_scope.dart';

Future<void> showOutboxEnqueueDialog(
  BuildContext context, {
  required AppRepository repo,
  required String kind,
  String? refId,
  required String title,
  required String subtitle,
}) async {
  final controller = TextEditingController();
  final text = await showDialog<String>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(subtitle, style: Theme.of(ctx).textTheme.bodySmall?.copyWith(color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 6,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Только то, что готовы зафиксировать',
                ),
                autofocus: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('В очередь')),
        ],
      );
    },
  );

  controller.dispose();

  final note = text;
  if (note == null || note.isEmpty) {
    return;
  }

  await repo.enqueueOutbox(kind: kind, refId: refId, body: note, meta: <String, Object?>{'source_label': subtitle});

  if (context.mounted) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(const SnackBar(content: Text('Добавлено в офлайн-очередь')));
  }
}

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = RepositoryScope.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Практика', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Техники'),
            Tab(text: 'Советы психолога'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              ListenableBuilder(
                listenable: repo,
                builder: (context, _) => _TechniquesList(repo: repo),
              ),
              ListenableBuilder(
                listenable: repo,
                builder: (context, _) => _TipsList(repo: repo),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TechniquesList extends StatelessWidget {
  const _TechniquesList({required this.repo});

  final AppRepository repo;

  @override
  Widget build(BuildContext context) {
    final techniques = repo.techniques;

    return ListView.separated(
      padding: const EdgeInsets.only(top: 16),
      itemCount: techniques.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final t = techniques[index];
        return Card(
          child: ListTile(
            title: Text(t.title),
            subtitle: Text('${t.subtitle} · ${t.durationHint}', maxLines: 2),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => TechniqueDetailScreen(technique: t, repo: repo)),
              );
            },
          ),
        );
      },
    );
  }
}

class TechniqueDetailScreen extends StatelessWidget {
  const TechniqueDetailScreen({super.key, required this.technique, required this.repo});

  final TechniqueJson technique;
  final AppRepository repo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(technique.title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(technique.subtitle, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Ориентир по времени: ${technique.durationHint}', style: theme.textTheme.bodySmall),
          const SizedBox(height: 20),
          for (var i = 0; i < technique.steps.length; i++) ...[
            Text('Шаг ${i + 1}', style: theme.textTheme.labelLarge),
            const SizedBox(height: 6),
            Text(technique.steps[i], style: theme.textTheme.bodyLarge?.copyWith(height: 1.4)),
            const SizedBox(height: 14),
          ],
          FilledButton(
            onPressed: () async {
              await repo.markTechniquePracticed(technique.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Спасибо за практику. Это сохранено локально.')),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Отметить «я попробовал(а)»'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => showOutboxEnqueueDialog(
              context,
              repo: repo,
              kind: 'technique_journal',
              refId: technique.id,
              title: 'Заметка о практике',
              subtitle: technique.title,
            ),
            icon: const Icon(Icons.queue_play_next_outlined),
            label: const Text('Текстовая заметка → очередь'),
          ),
        ],
      ),
    );
  }
}

class _TipsList extends StatelessWidget {
  const _TipsList({required this.repo});

  final AppRepository repo;

  @override
  Widget build(BuildContext context) {
    final tips = repo.tips;

    return ListView.separated(
      padding: const EdgeInsets.only(top: 16),
      itemCount: tips.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final tip = tips[index];
        return Card(
          child: ListTile(
            title: Text(tip.title),
            subtitle: Text(tip.category, style: Theme.of(context).textTheme.labelMedium),
            trailing: const Icon(Icons.article_outlined),
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => TipDetailScreen(tip: tip, repo: repo)),
              );
            },
          ),
        );
      },
    );
  }
}

class TipDetailScreen extends StatefulWidget {
  const TipDetailScreen({super.key, required this.tip, required this.repo});

  final PsychologistTipJson tip;
  final AppRepository repo;

  @override
  State<TipDetailScreen> createState() => _TipDetailScreenState();
}

class _TipDetailScreenState extends State<TipDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await widget.repo.registerTipOpened(widget.tip.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.tip.title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Chip(label: Text(widget.tip.category)),
          const SizedBox(height: 12),
          SelectableText(
            widget.tip.body,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.42),
          ),
          const SizedBox(height: 20),
          Text(
            'Материал для самопросветления. Если тревога нарастает — обратитесь к профильному специалисту.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 28),
          OutlinedButton.icon(
            onPressed: () => showOutboxEnqueueDialog(
              context,
              repo: widget.repo,
              kind: 'psychologist_tip_journal',
              refId: widget.tip.id,
              title: 'Мои мысли после совета',
              subtitle: widget.tip.title,
            ),
            icon: const Icon(Icons.edit_note_outlined),
            label: const Text('Ответ или инсайт → очередь'),
          ),
        ],
      ),
    );
  }
}
