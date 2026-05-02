import 'package:flutter/material.dart';

ThemeData buildPastelTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF7CB3E8),
      secondary: const Color(0xFF94D4C4),
      tertiary: const Color(0xFFC4B6E8),
      brightness: Brightness.light,
      surface: const Color(0xFFF7FAFB),
    ),
    appBarTheme: const AppBarTheme(centerTitle: true, scrolledUnderElevation: 0),
    cardTheme: CardThemeData(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      elevation: 0,
      indicatorColor: Colors.white.withValues(alpha: 0.35),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
      },
    ),
  );
}

Widget pastelBackground(BuildContext context, {required Widget child}) {
  final scheme = Theme.of(context).colorScheme;
  return DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(scheme.surface, scheme.primaryContainer, 0.35)!,
          scheme.surface,
          Color.lerp(scheme.surface, scheme.tertiaryContainer, 0.28)!,
        ],
      ),
    ),
    child: child,
  );
}
