import 'dart:math';

import 'package:flutter/material.dart';

import '../notify/repository_scope.dart';

class _Chip {
  const _Chip({required this.id, required this.color});

  final int id;
  final Color color;
}

/// Перетаскивание полосок: порядок по возрастанию оттенка HSV целевой палитры.
class CalmColorsGameScreen extends StatefulWidget {
  const CalmColorsGameScreen({super.key});

  @override
  State<CalmColorsGameScreen> createState() => _CalmColorsGameScreenState();
}

class _CalmColorsGameScreenState extends State<CalmColorsGameScreen> {
  late List<_Chip> _palette;
  late List<_Chip> _order;
  late List<_Chip> _target;
  final _rng = Random();
  bool _won = false;

  @override
  void initState() {
    super.initState();
    const colors = [
      Color(0xFF91C9F5),
      Color(0xFFA8E8D9),
      Color(0xFFB9B7F7),
      Color(0xFFFFF0C4),
    ];
    _palette = [
      _Chip(id: 0, color: colors[0]),
      _Chip(id: 1, color: colors[1]),
      _Chip(id: 2, color: colors[2]),
      _Chip(id: 3, color: colors[3]),
    ];
    _target = List<_Chip>.from(_palette)
      ..sort((a, b) => HSVColor.fromColor(a.color).hue.compareTo(HSVColor.fromColor(b.color).hue));
    _order = List<_Chip>.from(_target)..shuffle(_rng);
    while (_sameOrderIds(_order, _target)) {
      _order.shuffle(_rng);
    }
  }

  bool _sameOrderIds(List<_Chip> a, List<_Chip> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) {
        return false;
      }
    }
    return true;
  }

  Future<void> _checkWin() async {
    if (_won || !_sameOrderIds(_order, _target)) {
      return;
    }
    _won = true;
    setState(() {});
    await RepositoryScope.of(context).logActivity('colors_complete');
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Оттенки в спокойном порядке — отличная работа внимательности.')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Радуга спокойствия')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Перетащите блоки так, чтобы градиент шёл от более «холодного» цвета к более тёплому.',
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.35),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: ReorderableListView.builder(
                itemCount: _order.length,
                onReorder: (oldI, newI) {
                  setState(() {
                    if (newI > oldI) {
                      newI -= 1;
                    }
                    final item = _order.removeAt(oldI);
                    _order.insert(newI, item);
                  });
                  _checkWin();
                },
                itemBuilder: (context, index) {
                  final c = _order[index];
                  return Card(
                    key: ValueKey<int>(c.id),
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: c.color,
                          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.12)),
                        ),
                      ),
                      title: Text('Оттенок «${['А', 'Б', 'В', 'Г'][c.id]}»'),
                      trailing: const Icon(Icons.drag_handle_rounded),
                    ),
                  );
                },
              ),
            ),
            if (_won)
              SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Назад')),
              ),
          ],
        ),
      ),
    );
  }
}
