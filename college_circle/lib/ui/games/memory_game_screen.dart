import 'dart:math';

import 'package:flutter/material.dart';

import '../notify/repository_scope.dart';

/// Совпадение 4 пар мягких символов.
class MemoryGameScreen extends StatefulWidget {
  const MemoryGameScreen({super.key});

  @override
  State<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _Card {
  _Card({required this.id, required this.symbol, required this.pairId});

  final int id;
  final String symbol;
  final int pairId;
  bool revealed = false;
  bool matched = false;
}

class _MemoryGameScreenState extends State<MemoryGameScreen> {
  final _rng = Random();
  late List<_Card> _cards;
  int? _firstIndex;
  bool _lock = false;
  bool _won = false;
  int _moves = 0;

  @override
  void initState() {
    super.initState();
    const symbols = ['🌿', '🍵', '☁️', '🌙'];
    final pairs = <_Card>[];
    var nid = 0;
    for (var i = 0; i < symbols.length; i++) {
      pairs.add(_Card(id: nid++, symbol: symbols[i], pairId: i));
      pairs.add(_Card(id: nid++, symbol: symbols[i], pairId: i));
    }
    pairs.shuffle(_rng);
    _cards = pairs;
  }

  Future<void> _onWin() async {
    await RepositoryScope.of(context).logActivity('memory_complete');
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Все пары собраны — заметность и спокойствие.')));
  }

  Future<void> _tap(int index) async {
    if (_lock || _won) {
      return;
    }
    final c = _cards[index];
    if (c.matched || c.revealed) {
      return;
    }
    setState(() {
      c.revealed = true;
      if (_firstIndex == null) {
        _firstIndex = index;
      } else {
        _lock = true;
        _moves++;
      }
    });
    if (_firstIndex == null) {
      return;
    }
    final i0 = _firstIndex!;
    final i1 = index;
    if (i0 == i1) {
      _firstIndex = null;
      setState(() => _lock = false);
      return;
    }
    final a = _cards[i0];
    final b = _cards[i1];
    if (a.pairId == b.pairId) {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (!mounted) {
        return;
      }
      setState(() {
        a.matched = true;
        b.matched = true;
        _firstIndex = null;
        _lock = false;
      });
      if (_cards.every((e) => e.matched)) {
        _won = true;
        await _onWin();
        setState(() {});
      }
    } else {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (!mounted) {
        return;
      }
      setState(() {
        a.revealed = false;
        b.revealed = false;
        _firstIndex = null;
        _lock = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Память мятных карточек')),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Найдите пары одинаковых символов. Спешить не нужно.', style: theme.textTheme.bodyLarge),
            const SizedBox(height: 8),
            Text('Шагов: $_moves', style: theme.textTheme.labelLarge),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1,
                ),
                itemCount: _cards.length,
                itemBuilder: (context, i) {
                  final c = _cards[i];
                  final show = c.revealed || c.matched;
                  return GestureDetector(
                    onTap: () => _tap(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: c.matched
                            ? theme.colorScheme.tertiaryContainer.withValues(alpha: 0.35)
                            : theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
                      ),
                      alignment: Alignment.center,
                      child: show
                          ? Text(c.symbol, style: const TextStyle(fontSize: 30))
                          : Icon(Icons.question_mark_rounded, color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.55)),
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
