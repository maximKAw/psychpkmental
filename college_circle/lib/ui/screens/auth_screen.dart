import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../data/models/catalog_models.dart';
import '../notify/repository_scope.dart';
import 'registration_form_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _identityCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _pin2Ctrl = TextEditingController();

  bool _busy = false;

  @override
  void dispose() {
    _identityCtrl.dispose();
    _pinCtrl.dispose();
    _pin2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _openRegistration() async {
    if (!hasRegistrationFormUrl) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ссылку на анкету задают через dart-define GOOGLE_FORM_URL')));
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const RegistrationFormScreen()),
    );
    if (!mounted) {
      return;
    }
    await RepositoryScope.of(context).trySyncRemoteCatalog();
  }

  Future<void> _submit() async {
    final repo = RepositoryScope.of(context);
    final messenger = ScaffoldMessenger.of(context);

    FocusScope.of(context).unfocus();
    setState(() => _busy = true);

    try {
      final typed = _identityCtrl.text.trim();
      if (typed.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Укажите email или имя так, как после синхронизации в users.json.')),
        );
        return;
      }

      AllowedUserJson? roster;
      try {
        roster = repo.resolveUserForSignIn(typed);
      } on ArgumentError catch (e) {
        messenger.showSnackBar(SnackBar(content: Text('${e.message ?? e.toString()}')));
        return;
      }
      if (roster == null) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Такого участника пока нет в списке. Заполните анкету и дождитесь, когда куратор синхронизирует таблицу с users.json — затем нажмите «Подтянуть каталог» на экране «Сегодня».',
            ),
          ),
        );
        return;
      }

      final hasCred = await repo.credentialExistsForUserId(roster.id);
      if (hasCred) {
        await repo.loginWithPinForUser(roster, _pinCtrl.text);
      } else {
        await repo.enrollAndLoginUser(roster, _pinCtrl.text, _pin2Ctrl.text);
      }

      if (!mounted) {
        return;
      }
      messenger.showSnackBar(const SnackBar(content: Text('Добро пожаловать!')));
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = RepositoryScope.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Колледж‑круг', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(
                    'Регистрация через Google Forms → таблица → users.json на GitHub Pages. Вход локально по email или имени; PIN только на этом устройстве.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.35),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _openRegistration,
                    icon: const Icon(Icons.description_outlined),
                    label: Text(
                      hasRegistrationFormUrl ? 'Заполнить анкету регистрации' : 'Анкета (нет GOOGLE_FORM_URL)',
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Вход', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _identityCtrl,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            decoration: const InputDecoration(
                              labelText: 'Email или полное имя',
                              helperText:
                                  'Совпадение как в последней версии users.json (после синхронизации с Pages). Если имён несколько — используйте email.',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _pinCtrl,
                            keyboardType: TextInputType.number,
                            obscureText: true,
                            decoration: const InputDecoration(labelText: 'PIN (только цифры)'),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _pin2Ctrl,
                            keyboardType: TextInputType.number,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Повтор PIN',
                              helperText: 'При первом входе на устройстве; у повторных не проверяется.',
                            ),
                          ),
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: _busy ? null : _submit,
                            child: _busy
                                ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Text('Продолжить'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListenableBuilder(
                    listenable: repo,
                    builder: (context, _) {
                      if (repo.lastRemoteError == null) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        'Каталог с сети: ${repo.lastRemoteError}',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
