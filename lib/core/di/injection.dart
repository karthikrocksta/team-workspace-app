import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';

import '../constants/api_constants.dart';
import '../network/dio_client.dart';
import '../network/network_info.dart';

// Auth feature
import '../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../features/auth/data/datasources/firebase_auth_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/get_current_user_usecase.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/sign_up_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

// Tasks feature
import '../../features/tasks/data/datasources/task_local_datasource.dart';
import '../../features/tasks/data/datasources/task_remote_datasource.dart';
import '../../features/tasks/data/repositories/task_repository_impl.dart';
import '../../features/tasks/domain/repositories/task_repository.dart';
import '../../features/tasks/domain/usecases/create_task_usecase.dart';
import '../../features/tasks/domain/usecases/get_task_by_id_usecase.dart';
import '../../features/tasks/domain/usecases/get_tasks_usecase.dart';
import '../../features/tasks/domain/usecases/update_task_usecase.dart';
import '../../features/tasks/presentation/bloc/task_detail/task_detail_bloc.dart';
import '../../features/tasks/presentation/bloc/task_form/task_form_bloc.dart';
import '../../features/tasks/presentation/bloc/task_list/task_list_bloc.dart';

/// Global service locator. Called once from `main.dart` before `runApp`.
final GetIt sl = GetIt.instance;

Future<void> initDependencies() async {
  // ---------------------------------------------------------------------
  // External packages / SDKs
  // ---------------------------------------------------------------------
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => Dio());
  sl.registerLazySingleton(() => Connectivity());
  sl.registerLazySingleton(() => DioClient(sl()));

  final authSessionBox = await Hive.openBox(HiveBoxes.authSessionBox);
  final taskCacheBox = await Hive.openBox(HiveBoxes.taskCacheBox);
  sl.registerLazySingleton<Box>(() => authSessionBox, instanceName: HiveBoxes.authSessionBox);
  sl.registerLazySingleton<Box>(() => taskCacheBox, instanceName: HiveBoxes.taskCacheBox);

  // ---------------------------------------------------------------------
  // Core
  // ---------------------------------------------------------------------
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));

  // ---------------------------------------------------------------------
  // Auth feature
  // ---------------------------------------------------------------------
  sl.registerLazySingleton<FirebaseAuthDataSource>(() => FirebaseAuthDataSourceImpl(sl()));
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(sl<Box>(instanceName: HiveBoxes.authSessionBox)),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl(), localDataSource: sl()),
  );
  sl.registerLazySingleton(() => SignUpUseCase(sl()));
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));
  sl.registerFactory(
    () => AuthBloc(
      signUpUseCase: sl(),
      loginUseCase: sl(),
      logoutUseCase: sl(),
      getCurrentUserUseCase: sl(),
    ),
  );

  // ---------------------------------------------------------------------
  // Tasks feature
  // ---------------------------------------------------------------------
  sl.registerLazySingleton<TaskRemoteDataSource>(() => TaskRemoteDataSourceImpl(sl<DioClient>().dio));
  sl.registerLazySingleton<TaskLocalDataSource>(
    () => TaskLocalDataSourceImpl(sl<Box>(instanceName: HiveBoxes.taskCacheBox)),
  );
  sl.registerLazySingleton<TaskRepository>(
    () => TaskRepositoryImpl(remoteDataSource: sl(), localDataSource: sl(), networkInfo: sl()),
  );

  sl.registerLazySingleton(() => GetTasksUseCase(sl()));
  sl.registerLazySingleton(() => GetTaskByIdUseCase(sl()));
  sl.registerLazySingleton(() => CreateTaskUseCase(sl()));
  sl.registerLazySingleton(() => UpdateTaskUseCase(sl()));

  sl.registerFactory(() => TaskListBloc(getTasksUseCase: sl()));
  sl.registerFactory(() => TaskDetailBloc(getTaskByIdUseCase: sl(), updateTaskUseCase: sl()));
  sl.registerFactory(() => TaskFormBloc(createTaskUseCase: sl(), updateTaskUseCase: sl()));
}
