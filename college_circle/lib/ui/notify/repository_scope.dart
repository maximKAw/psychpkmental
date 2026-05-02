import 'package:flutter/material.dart';

import '../../data/repositories/app_repository.dart';

class RepositoryScope extends InheritedWidget {
  const RepositoryScope({super.key, required this.repository, required super.child});

  final AppRepository repository;

  static AppRepository of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<RepositoryScope>();
    assert(scope != null, 'RepositoryScope не найден');
    return scope!.repository;
  }

  @override
  bool updateShouldNotify(covariant RepositoryScope oldWidget) => oldWidget.repository != repository;
}
