import 'package:flutter/material.dart';

import '../../data/models/catalog_models.dart';
import '../../data/repositories/app_repository.dart';
import '../games/achievement_icons.dart';
import '../notify/repository_scope.dart';
import 'sync_outbox_screen.dart';

class ProfileGalleryScreen extends StatefulWidget {
  const ProfileGalleryScreen({super.key});

  @override
  State<ProfileGalleryScreen> createState() => _ProfileGalleryScreenState();
}

class _ProfileGalleryScreenState extends State<ProfileGalleryScreen> {
  final _name = TextEditingController();
  final _course = TextEditingController();
  final _interests = TextEditingController();
  Future<UserProfileRow>? _profileFuture;
  Future<List<AchievementRow>>? _achFuture;
  AppRepository? _repo;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final r = RepositoryScope.of(context);
    if (_repo != r) {
      _repo?.removeListener(_refresh);
      _repo = r;
      _repo!.addListener(_refresh);
    }
    _profileFuture ??= _repo!.loadProfile();
    _profileFuture!.then((p) {
      if (!mounted) {
        return;
      }
      _name.text = p.displayName;
      _course.text = p.course;
      _interests.text = p.interests;
    });
    _achFuture ??= _repo!.loadAchievements();
  }

  void _refresh() {
    setState(() {
      _profileFuture = _repo!.loadProfile();
      _achFuture = _repo!.loadAchievements();
    });
  }

  @override
  void dispose() {
    _repo?.removeListener(_refresh);
    _name.dispose();
    _course.dispose();
    _interests.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final repo = RepositoryScope.of(context);
    await repo.saveProfile(displayName: _name.text.trim(), course: _course.text.trim(), interests: _interests.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Профиль сохранён локально')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Вы и галерея', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Профиль', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ListenableBuilder(
                    listenable: RepositoryScope.of(context),
                    builder: (context, _) {
                      final r = RepositoryScope.of(context);
                      return Text(
                        'Вошли как: ${r.sessionBannerName} · ${r.sessionAccountSubtitle}',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Как вас звать?', hintText: 'Имя или никнейм'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _course,
                    decoration: const InputDecoration(labelText: 'Курс / группа'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _interests,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Интересы (через запятую)'),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(onPressed: _save, child: const Text('Сохранить профиль')),
                  ),
                  Text(
                    'Каждое сохранение профиля добавляет снимок в офлайн-очередь (для экспорта позже).',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await RepositoryScope.of(context).logout();
                      if (!context.mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Вы вышли из аккаунта')));
                    },
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Выйти'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          ListenableBuilder(
            listenable: RepositoryScope.of(context),
            builder: (context, _) {
              return FutureBuilder<int>(
                future: RepositoryScope.of(context).pendingOutboxCount(),
                builder: (context, snap) {
                  final n = snap.data ?? 0;
                  return Card(
                    child: ListTile(
                      leading: Badge.count(
                        count: n,
                        isLabelVisible: n > 0,
                        child: Icon(Icons.upload_file_rounded, color: theme.colorScheme.primary),
                      ),
                      title: const Text('Очередь ответов'),
                      subtitle: const Text(
                        'POST на свой сервер или ручное «принято» — экран синхронизации',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () async {
                        await Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => const SyncOutboxScreen()));
                        _refresh();
                      },
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 22),
          Text('Галерея достижений', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          FutureBuilder<List<AchievementRow>>(
            future: _achFuture,
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
              }
              final rows = snap.data!;
              return ListenableBuilder(
                listenable: _repo!,
                builder: (context, _) {
                  return FutureBuilder<List<AchievementRow>>(
                    future: _repo!.loadAchievements(),
                    builder: (context, s2) {
                      final items = s2.data ?? rows;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.95, crossAxisSpacing: 10, mainAxisSpacing: 10),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final a = items[index];
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    achievementIconAsset(a.icon),
                                    size: 32,
                                    color: a.unlocked ? theme.colorScheme.primary : theme.colorScheme.outline,
                                  ),
                                  const Spacer(),
                                  Text(
                                    a.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: a.unlocked ? null : theme.colorScheme.outline,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    a.unlocked ? a.description : 'Пока скрыто — продолжайте в приложении без спешки.',
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: a.unlocked ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.outline,
                                      height: 1.26,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
