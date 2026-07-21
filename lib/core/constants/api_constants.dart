class ApiConstants {
  ApiConstants._();

  /// Public REST API used to back the task dashboard.
  /// dummyjson.com exposes a paginated `/todos` endpoint (limit/skip) which
  /// we map to our Task domain model - see [TaskRemoteDataSourceImpl].
  static const String baseUrl = 'https://dummyjson.com';

  static const String todosEndpoint = '/todos';
  static const String todoByIdEndpoint = '/todos'; // + /{id}
  static const String addTodoEndpoint = '/todos/add';

  static const int defaultPageSize = 10;
}

class HiveBoxes {
  HiveBoxes._();
  static const String taskCacheBox = 'task_cache_box';
  static const String authSessionBox = 'auth_session_box';
}

class HiveKeys {
  HiveKeys._();
  static const String cachedTasks = 'CACHED_TASKS';
  static const String localOnlyTasks = 'LOCAL_ONLY_TASKS';
  static const String pendingSync = 'PENDING_SYNC_OPS';
  static const String cachedUser = 'CACHED_USER';
}
