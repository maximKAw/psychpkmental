import 'dart:math';

import 'package:flutter/material.dart';

import '../notify/repository_scope.dart';

class _LetterPiece {
  const _LetterPiece(this.char, this.indexInWord);

  final String char;
  final int indexInWord;
}

/// Три коротких слова без таймера: соберите буквы в правильном порядке (дубликаты учтены).
class WordUnscrambleGameScreen extends StatefulWidget {
  const WordUnscrambleGameScreen({super.key});

  @override
  State<WordUnscrambleGameScreen> createState() => _WordUnscrambleGameScreenState();
}

class _WordUnscrambleGameScreenState extends State<WordUnscrambleGameScreen> {
  static const _words = ['ПОКОЙ', 'ТЕПЛО', 'СМЕХ'];
  final _rng = Random();

  var _stage = 0;
  late List<_LetterPiece> _pool;
  final List<_LetterPiece> _answer = [];

  String get _target => _words[_stage];

  @override
  void initState() {
    super.initState();
    _preparePool();
  }

  void _preparePool() {
    final w = _target;
    _pool = [
      for (var i = 0; i < w.length; i++) _LetterPiece(w.substring(i, i + 1), i),
    ]..shuffle(_rng);
    _answer.clear();
  }

  Future<void> _completeAll() async {
    await RepositoryScope.of(context).logActivity('word_scr_complete');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Три слова собраны — отличное внимание.')));
      Navigator.pop(context);
    }
  }

  void _toAnswer(_LetterPiece p) {
    setState(() {
      _pool.remove(p);
      _answer.add(p);
    });
    _maybeAdvance();
  }

  void _backToPool(_LetterPiece p) {
    setState(() {
      _answer.remove(p);
      _pool.add(p);
    });
  }

  void _maybeAdvance() {
    final target = _target;
    if (_answer.length != target.length) {
      return;
    }
    final composed = _answer.map((p) => p.char).join();
    if (composed != target) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text('Не то слово («$composed»). Поле очищаем для новой попытки.'),
        ),
      );
      setState(() {
        _pool.addAll(_answer);
        _answer.clear();
        _pool.shuffle(_rng);
      });
      return;
    }
    if (_stage >= _words.length - 1) {
      _completeAll();
      return;
    }
    setState(() {
      _stage++;
      _preparePool();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Слова без спешки')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Слово ${_stage + 1} из ${_words.length}', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Text(
              'Соберите «$_target» по буквам. Неверный порядок не ломает уровень — просто поправьте строку ниже.',
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
            ),
            const SizedBox(height: 20),
            Text('Ответ', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: _answer.isEmpty
                    ? [
                        Text(
                          'нажимайте на буквы снизу',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ]
                    : _answer
                          .map(
                            (p) => ActionChip(
                              label: Text(p.char),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              onPressed: () => _backToPool(p),
                            ),
                          )
                          .toList(),
              ),
            ),
            const SizedBox(height: 20),
            Text('Буквы', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: _pool
                        .map(
                          (p) => FilledButton.tonal(
                            onPressed: () => _toAnswer(p),
                            child: Text(p.char, style: theme.textTheme.titleMedium),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () {
                setState(_preparePool);
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Перемешать строку ниже заново'),
            ),
          ],
        ),
      ),
    );
  }
}
