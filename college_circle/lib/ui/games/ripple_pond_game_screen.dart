import 'package:flutter/material.dart';

import '../notify/repository_scope.dart';

/// Спокойные «круги на воде»: 10 мягких касаний без спешки.
class RipplePondGameScreen extends StatefulWidget {
  const RipplePondGameScreen({super.key});

  @override
  State<RipplePondGameScreen> createState() => _RipplePondGameScreenState();
}

class _RipplePondGameScreenState extends State<RipplePondGameScreen> with SingleTickerProviderStateMixin {
  static const _goal = 10;
  var _count = 0;
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  Future<void> _tap() async {
    if (_count >= _goal) {
      return;
    }
    setState(() => _count++);
    _pulse.forward(from: 0);
    if (_count >= _goal) {
      await RepositoryScope.of(context).logActivity('ripple_complete');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Десять спокойных касаний — готово.')));
      }
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = _count >= _goal;

    return Scaffold(
      appBar: AppBar(title: const Text('Пруд спокойных кругов')),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: done ? null : _tap,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                'Касайтесь экрана в своём темпе. Цель — $_goal спокойных касаний.',
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.35),
              ),
              const Spacer(),
              ScaleTransition(
                scale: Tween<double>(begin: 0.97, end: 1).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeOutCubic)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        theme.colorScheme.primaryContainer.withValues(alpha: done ? 0.75 : 0.45),
                        theme.colorScheme.tertiaryContainer.withValues(alpha: 0.35),
                      ],
                    ),
                    boxShadow: [BoxShadow(blurRadius: 28, spreadRadius: 2, color: theme.colorScheme.primary.withValues(alpha: 0.08))],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    done ? 'Готово' : '$_count / $_goal',
                    style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                done ? 'Можете вернуться в хаб игр.' : 'Пауза между касаниями — хоть сколько угодно.',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (done)
                SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Назад'))),
            ],
          ),
        ),
      ),
    );
  }
}
