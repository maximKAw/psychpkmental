import 'package:flutter/material.dart';

import '../games/breathing_game_screen.dart';
import '../games/calm_colors_game_screen.dart';
import '../games/gentle_pattern_game_screen.dart';
import '../games/gratitude_three_game_screen.dart';
import '../games/memory_game_screen.dart';
import '../games/ripple_pond_game_screen.dart';
import '../games/word_unscramble_game_screen.dart';

class GamesHubScreen extends StatelessWidget {
  const GamesHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Мини‑игры', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Text(
            'Короткие и без соревнования по очкам. Остановка в любой момент — норма.',
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.35),
          ),
          const SizedBox(height: 20),
          _GameTile(
            title: 'Дыхание круга',
            subtitle: 'Три цикла вдоха и выдоха с мягкой анимацией.',
            icon: Icons.air_rounded,
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const BreathingGameScreen())),
          ),
          _GameTile(
            title: 'Память мятных карточек',
            subtitle: 'Соберите 4 спокойных пары — без таймера.',
            icon: Icons.grid_view_rounded,
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const MemoryGameScreen())),
          ),
          _GameTile(
            title: 'Радуга спокойствия',
            subtitle: 'Перетащите оттенки в спокойный порядок.',
            icon: Icons.palette_rounded,
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const CalmColorsGameScreen())),
          ),
          _GameTile(
            title: 'Пруд спокойных кругов',
            subtitle: 'Десять мягких касаний — как круги на воде.',
            icon: Icons.water_drop_rounded,
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const RipplePondGameScreen())),
          ),
          _GameTile(
            title: 'Слова без спешки',
            subtitle: 'Три коротких слова из букв в своём темпе.',
            icon: Icons.sort_by_alpha_rounded,
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const WordUnscrambleGameScreen())),
          ),
          _GameTile(
            title: 'Мягкий узор',
            subtitle: 'Спокойная демонстрация и повтор трёх цветов.',
            icon: Icons.blur_on_rounded,
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const GentlePatternGameScreen())),
          ),
          _GameTile(
            title: 'Три слова к себе',
            subtitle: 'Выберите три добрых слова — без «правильного» списка.',
            icon: Icons.favorite_border_rounded,
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const GratitudeThreeGameScreen())),
          ),
        ],
      ),
    );
  }
}

class _GameTile extends StatelessWidget {
  const _GameTile({required this.title, required this.subtitle, required this.icon, required this.onTap});

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 42, color: theme.colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(Icons.play_circle_outline_rounded, color: theme.colorScheme.secondary),
            ],
          ),
        ),
      ),
    );
  }
}
