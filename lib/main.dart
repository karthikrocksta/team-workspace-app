import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/di/injection.dart';
import 'core/utils/app_logger.dart';
import 'features/tasks/data/repositories/task_repository_impl.dart';
import 'features/tasks/domain/repositories/task_repository.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    // Allows the app to still boot (e.g. in CI, or before firebase_options.dart
    // has been generated) so the rest of the UI can be inspected. Real auth
    // calls will fail until a valid Firebase project is configured - see README.
    AppLogger.warning('Firebase failed to initialize: $e');
  }

  await initDependencies();

  // Bonus: opportunistically sync any offline-created/edited tasks whenever
  // connectivity is restored.
  Connectivity().onConnectivityChanged.listen((result) {
    if (!result.contains(ConnectivityResult.none)) {
      final repository = sl<TaskRepository>();
      if (repository is TaskRepositoryImpl) {
        repository.syncPendingChanges();
      }
    }
  });

  runApp(const TeamWorkspaceApp());
}
