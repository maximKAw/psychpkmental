import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'data/db/app_database.dart';
import 'data/repositories/app_repository.dart';
import 'theme/app_theme.dart';
import 'ui/notify/repository_scope.dart';
import 'ui/screens/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  final db = await AppDatabase.open();
  final repository = AppRepository(db);
  await repository.initialize();

  runApp(
    RepositoryScope(
      repository: repository,
      child: MaterialApp(title: 'Колледж‑круг', theme: buildPastelTheme(), home: const AuthGate()),
    ),
  );
}
