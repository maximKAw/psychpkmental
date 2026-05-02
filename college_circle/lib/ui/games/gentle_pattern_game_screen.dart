import 'dart:math';

import 'package:flutter/material.dart';

import '../notify/repository_scope.dart';

/// Спокойный «повтор узора»: три мягких цвета, медленная демонстрация.
class GentlePatternGameScreen extends StatefulWidget {
  const GentlePatternGameScreen({super.key});

  @override
  State<GentlePatternGameScreen> createState() => _GentlePatternGameScreenState();
}

class _GentlePatternGameScreenState extends State<GentlePatternGameScreen> {
  static const List<Color> _palette = [
    Color(0xFF8ECAE6),
    Color(0xFF99F6E4),
    Color(0xFFCBB5F8),
  ];

  final _rng = Random();
  late List<int> _pattern;
  var _demoIndex = -1;
  var _listening = false;
  final List<int> _user = [];
  var _busy = false;
  var _done = false;

  @override
  void initState() {
    super.initState();
    _pattern = List<int>.generate(3, (_) => _rng.nextInt(3));
  }

  Future<void> _demo() async {
    if (_busy || _listening || _done) {
      return;
    }
    setState(() => _busy = true);
    for (var i = 0; i < _pattern.length; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) {
        return;
      }
      setState(() => _demoIndex = _pattern[i]);
      await Future<void>.delayed(const Duration(milliseconds: 650));
      if (!mounted) {
        return;
      }
      setState(() => _demoIndex = -1);
      await Future<void>.delayed(const Duration(milliseconds: 180));
    }
    setState(() {
      _busy = false;
      _listening = true;
      _user.clear();
    });
  }

  Future<void> _pushColor(int i) async {
    if (!_listening || _busy || _done) {
      return;
    }
    setState(() => _user.add(i));
    if (_user.length < _pattern.length) {
      return;
    }
    var ok = true;
    for (var k = 0; k < _pattern.length; k++) {
      if (_user[k] != _pattern[k]) {
        ok = false;
        break;
      }
    }
    if (!ok) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Почти — посмотрите демонстрацию ещё раз и попробуйте спокойно.')),
      );
      setState(() {
        _user.clear();
        _listening = false;
      });
      return;
    }
    setState(() {
      _done = true;
      _listening = false;
    });
    await RepositoryScope.of(context).logActivity('pattern_soft_complete');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Вы повторили мягкий узор без спешки.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Мягкий узор')),
      body: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Сначала смотрите, как три плитки мягко подсвечиваются, затем нажмите те же три в том же порядке.',
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.35),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(onPressed: _busy || _done ? null : _demo, child: Text(_listening ? 'Ваш черёд нажать' : 'Показать узор медленно')),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(3, (i) {
                final pulse = !_done && _demoIndex == i;
                final baseOpacity = _listening ? 0.96 : _busy ? 0.74 : (!_done ? 0.78 : 0.55);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: GestureDetector(
                        onTap: _listening ? () => _pushColor(i) : null,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: pulse ? 1 : baseOpacity,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: _palette[i],
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                if (pulse)
                                  BoxShadow(
                                    blurRadius: 22,
                                    spreadRadius: 2,
                                    color: _palette[i].withValues(alpha: 0.55),
                                  ),
                              ],
                              border: Border.all(
                                color: theme.colorScheme.outline.withValues(alpha: _listening ? 0.35 : 0.14),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const Spacer(),
            if (_listening)
              Text('Шаг ${_user.length} из ${_pattern.length}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            if (_done) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Назад')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
