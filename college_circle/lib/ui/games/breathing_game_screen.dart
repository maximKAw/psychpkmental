import 'dart:async';

import 'package:flutter/material.dart';

import '../notify/repository_scope.dart';

/// Мягкое дыхание: три цикла «вдох / выдох» по секундам, круг живёт через `TweenAnimationBuilder`.
class BreathingGameScreen extends StatefulWidget {
  const BreathingGameScreen({super.key});

  @override
  State<BreathingGameScreen> createState() => _BreathingGameScreenState();
}

class _BreathingGameScreenState extends State<BreathingGameScreen> {
  Timer? _tick;
  bool _running = false;
  bool _done = false;
  int _cycle = 0;
  bool _inhale = true;
  int _secondsLeftInPhase = 4;

  static const _phaseLen = 4;
  static const _maxCycles = 3;

  void _start() {
    if (_done) {
      return;
    }
    setState(() {
      _running = true;
      _cycle = 0;
      _inhale = true;
      _secondsLeftInPhase = _phaseLen;
    });
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => _onSecond());
  }

  void _pause() {
    _tick?.cancel();
    setState(() => _running = false);
  }

  Future<void> _finish() async {
    if (_done) {
      return;
    }
    _tick?.cancel();
    _done = true;
    _running = false;
    setState(() {});
    await RepositoryScope.of(context).logActivity('breathing_complete');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Три цикла позади — хорошая работа с телом.')),
      );
    }
  }

  void _onSecond() {
    if (!_running || _done) {
      return;
    }
    var finished = false;
    setState(() {
      _secondsLeftInPhase--;
      if (_secondsLeftInPhase <= 0) {
        if (_inhale) {
          _inhale = false;
          _secondsLeftInPhase = _phaseLen;
        } else {
          _inhale = true;
          _secondsLeftInPhase = _phaseLen;
          _cycle++;
          if (_cycle >= _maxCycles) {
            finished = true;
          }
        }
      }
    });
    if (finished) {
      _finish();
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = !_running || _done ? 0.72 : (_inhale ? 1.06 : 0.68);

    return Scaffold(
      appBar: AppBar(title: const Text('Дыхание круга')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Три полных цикла. Если нужно — сделайте паузу или укоротите фазы воображаемо.',
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.35),
            ),
            const Spacer(),
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: scale, end: scale),
                duration: const Duration(seconds: 1),
                curve: Curves.easeInOut,
                builder: (context, s, child) => Transform.scale(scale: s, child: child),
                child: Container(
                  width: 210,
                  height: 210,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _done
                        ? 'Готово'
                        : !_running
                        ? 'Старт'
                        : '${_inhale ? "Вдох" : "Выдох"}\n$_secondsLeftInPhase с',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            const Spacer(),
            if (!_done) ...[
              Row(
                children: [
                  Expanded(child: FilledButton(onPressed: _running ? null : _start, child: const Text('Начать'))),
                  const SizedBox(width: 12),
                  Expanded(child: OutlinedButton(onPressed: _running ? _pause : null, child: const Text('Пауза'))),
                ],
              ),
            ] else
              SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Назад'))),
          ],
        ),
      ),
    );
  }
}
