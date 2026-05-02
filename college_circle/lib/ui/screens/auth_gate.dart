import 'package:flutter/material.dart';

import '../notify/repository_scope.dart';
import '../shell/main_shell.dart';
import 'auth_screen.dart';

/// Пока нет сохранённой сессии в SQLite — экран входа; иначе основной интерфейс.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    return ListenableBuilder(
      listenable: repo,
      builder: (_, __) => repo.isAuthenticated ? const MainShell() : const AuthScreen(),
    );
  }
}
