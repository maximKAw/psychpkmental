import 'package:flutter/material.dart';

import '../notify/repository_scope.dart';

/// Выберите три слова «к себе добра» без правильных/неправильных вариантов.
class GratitudeThreeGameScreen extends StatefulWidget {
  const GratitudeThreeGameScreen({super.key});

  @override
  State<GratitudeThreeGameScreen> createState() => _GratitudeThreeGameScreenState();
}

class _GratitudeThreeGameScreenState extends State<GratitudeThreeGameScreen> {
  static const _words = [
    'уют',
    'свет',
    'тепло',
    'друг',
    'музыка',
    'чай',
    'прогулка',
    'сон',
    'искренность',
    'нежность',
    'искра',
    'надежда',
  ];

  final Set<int> _picked = {};

  Future<void> _finish() async {
    await RepositoryScope.of(context).logActivity('gratitude_three_complete');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Готово — сохраните эти три слова где-нибудь рядом с собой.')));
      Navigator.pop(context);
    }
  }

  void _toggle(int i) {
    if (_picked.contains(i)) {
      setState(() => _picked.remove(i));
      return;
    }
    if (_picked.length >= 3) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(const SnackBar(content: Text('Уже три — снимите чип, чтобы заменить.')));
      return;
    }
    setState(() => _picked.add(i));
    if (_picked.length == 3) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!context.mounted) {
          return;
        }
        await _finish();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Три слова к себе')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Выберите ровно три слова — те, которые сегодня откликаются. Спешить не нужно; после третьего выбора игра закроется сама.',
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.35),
            ),
            const SizedBox(height: 16),
            Text('Выбрано: ${_picked.length} / 3', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: List.generate(_words.length, (i) {
                    final on = _picked.contains(i);
                    return FilterChip(
                      label: Text(_words[i]),
                      selected: on,
                      onSelected: (_) => _toggle(i),
                      showCheckmark: false,
                    );
                  }),
                ),
              ),
            ),
            Text(
              'Нет ошибочного набора — это про внимание и тёплую установку.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
