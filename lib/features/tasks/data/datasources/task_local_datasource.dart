import 'dart:convert';
import 'package:hive/hive.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../models/task_model.dart';

abstract class TaskLocalDataSource {
  /// Persists the latest page(s) of tasks so the dashboard can render
  /// something meaningful when the device goes offline.
  Future<void> cacheTasks(List<TaskModel> tasks);
  Future<List<TaskModel>> getCachedTasks();

  /// Tasks created/edited entirely on-device (either brand-new tasks, or
  /// edits made while offline). Kept separate from the remote cache so we
  /// can always show them "immediately in the UI" per the requirements and
  /// resync them later (bonus: offline sync on reconnect).
  Future<void> upsertLocalTask(TaskModel task);
  Future<List<TaskModel>> getLocalTasks();
  Future<void> removeLocalTask(String id);

  /// Bonus: offline-created/edited tasks are tracked here so they can be
  /// pushed to the remote API once connectivity returns.
  Future<void> markPendingSync(String id);
  Future<void> clearPendingSync(String id);
  Future<List<String>> getPendingSyncIds();
}

class TaskLocalDataSourceImpl implements TaskLocalDataSource {
  final Box box;

  TaskLocalDataSourceImpl(this.box);

  @override
  Future<void> cacheTasks(List<TaskModel> tasks) async {
    try {
      final encoded = jsonEncode(tasks.map((t) => t.toJson()).toList());
      await box.put(HiveKeys.cachedTasks, encoded);
    } catch (_) {
      throw const CacheException('Failed to cache tasks locally.');
    }
  }

  @override
  Future<List<TaskModel>> getCachedTasks() async {
    final raw = box.get(HiveKeys.cachedTasks) as String?;
    if (raw == null) return [];
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      return list.map(TaskModel.fromJson).toList();
    } catch (_) {
      throw const CacheException('Cached task data is corrupted.');
    }
  }

  @override
  Future<void> upsertLocalTask(TaskModel task) async {
    final tasks = await getLocalTasks();
    final index = tasks.indexWhere((t) => t.id == task.id);
    if (index >= 0) {
      tasks[index] = task;
    } else {
      tasks.insert(0, task);
    }
    final encoded = jsonEncode(tasks.map((t) => t.toJson()).toList());
    await box.put(HiveKeys.localOnlyTasks, encoded);
  }

  @override
  Future<List<TaskModel>> getLocalTasks() async {
    final raw = box.get(HiveKeys.localOnlyTasks) as String?;
    if (raw == null) return [];
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      return list.map(TaskModel.fromJson).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> removeLocalTask(String id) async {
    final tasks = await getLocalTasks();
    tasks.removeWhere((t) => t.id == id);
    final encoded = jsonEncode(tasks.map((t) => t.toJson()).toList());
    await box.put(HiveKeys.localOnlyTasks, encoded);
  }

  @override
  Future<void> markPendingSync(String id) async {
    final ids = await getPendingSyncIds();
    if (!ids.contains(id)) {
      ids.add(id);
      await box.put(HiveKeys.pendingSync, jsonEncode(ids));
    }
  }

  @override
  Future<void> clearPendingSync(String id) async {
    final ids = await getPendingSyncIds();
    ids.remove(id);
    await box.put(HiveKeys.pendingSync, jsonEncode(ids));
  }

  @override
  Future<List<String>> getPendingSyncIds() async {
    final raw = box.get(HiveKeys.pendingSync) as String?;
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List).cast<String>();
    } catch (_) {
      return [];
    }
  }
}
