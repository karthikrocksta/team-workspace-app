import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/entities/task_page.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_local_datasource.dart';
import '../datasources/task_remote_datasource.dart';
import '../models/task_model.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskRemoteDataSource remoteDataSource;
  final TaskLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  static const _uuid = Uuid();

  TaskRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, TaskPage>> getTasks({required int page, required int pageSize}) async {
    final localTasks = await localDataSource.getLocalTasks();
    final localById = {for (final t in localTasks) t.id: t};
    final newLocalOnly = localTasks.where((t) => t.isLocalOnly).toList();

    final isConnected = await networkInfo.isConnected;

    if (!isConnected) {
      // Offline: serve from cache, overlaying any local edits/creations so
      // the user still sees a consistent, most-recent view of their data.
      final cached = await localDataSource.getCachedTasks();
      final merged = cached.map((t) => localById[t.id] ?? t).toList();
      final combined = [...newLocalOnly, ...merged.where((t) => !newLocalOnly.any((l) => l.id == t.id))];
      return Right(TaskPage(tasks: combined, total: combined.length, hasReachedMax: true));
    }

    try {
      final skip = (page - 1) * pageSize;
      final (remoteTasks, total) = await remoteDataSource.getTasks(skip: skip, limit: pageSize);

      // Apply any local edits on top of the remote-sourced tasks.
      final merged = remoteTasks.map((t) => localById[t.id] ?? t).toList();

      // Prepend brand-new, locally created tasks only on the first page so
      // they don't get duplicated across subsequent pages.
      final pageTasks = page == 1 ? [...newLocalOnly, ...merged] : merged;

      if (page == 1) {
        await localDataSource.cacheTasks(merged);
      }

      final hasReachedMax = skip + remoteTasks.length >= total;
      return Right(TaskPage(tasks: pageTasks, total: total + newLocalOnly.length, hasReachedMax: hasReachedMax));
    } on ServerException catch (e) {
      // Network says "connected" but the request still failed (DNS hiccup,
      // server error, timeout) - fall back to cache so the user isn't
      // stranded, but surface the failure if there's nothing to show.
      final cached = await localDataSource.getCachedTasks();
      if (cached.isNotEmpty || newLocalOnly.isNotEmpty) {
        final merged = cached.map((t) => localById[t.id] ?? t).toList();
        final combined = [...newLocalOnly, ...merged];
        return Right(TaskPage(tasks: combined, total: combined.length, hasReachedMax: true));
      }
      return Left(ServerFailure(e.message));
    } catch (e) {
      AppLogger.error('Unexpected error fetching tasks', error: e);
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, TaskEntity>> getTaskById(String id) async {
    // Local-only or locally-edited tasks are always authoritative first.
    final localTasks = await localDataSource.getLocalTasks();
    final local = localTasks.where((t) => t.id == id).toList();
    if (local.isNotEmpty) return Right(local.first);

    final isConnected = await networkInfo.isConnected;
    if (!isConnected) {
      final cached = await localDataSource.getCachedTasks();
      final match = cached.where((t) => t.id == id).toList();
      if (match.isNotEmpty) return Right(match.first);
      return const Left(NetworkFailure());
    }

    try {
      final task = await remoteDataSource.getTaskById(id);
      return Right(task);
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      AppLogger.error('Unexpected error fetching task by id', error: e);
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, TaskEntity>> createTask(TaskEntity task) async {
    final newTask = TaskModel.fromEntity(
      task.copyWith(id: task.id.isNotEmpty ? task.id : _uuid.v4(), isLocalOnly: true),
    );

    final isConnected = await networkInfo.isConnected;

    if (!isConnected) {
      // Offline: save optimistically and queue for sync later (bonus).
      await localDataSource.upsertLocalTask(newTask);
      await localDataSource.markPendingSync(newTask.id);
      return Right(newTask);
    }

    try {
      await remoteDataSource.createTask(newTask);
      await localDataSource.upsertLocalTask(newTask);
      return Right(newTask);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      AppLogger.error('Unexpected error creating task', error: e);
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, TaskEntity>> updateTask(TaskEntity task) async {
    final updated = TaskModel.fromEntity(task);
    final isConnected = await networkInfo.isConnected;

    if (!isConnected) {
      await localDataSource.upsertLocalTask(updated);
      await localDataSource.markPendingSync(updated.id);
      return Right(updated);
    }

    try {
      final result = await remoteDataSource.updateTask(updated);
      await localDataSource.upsertLocalTask(TaskModel.fromEntity(result));
      return Right(result);
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      AppLogger.error('Unexpected error updating task', error: e);
      return const Left(UnknownFailure());
    }
  }

  /// Bonus: pushes any offline-made changes to the remote API once
  /// connectivity is restored. Safe to call repeatedly (e.g. on every
  /// connectivity-changed event) - it's a no-op when the queue is empty.
  Future<void> syncPendingChanges() async {
    final isConnected = await networkInfo.isConnected;
    if (!isConnected) return;

    final pendingIds = await localDataSource.getPendingSyncIds();
    if (pendingIds.isEmpty) return;

    final localTasks = await localDataSource.getLocalTasks();
    for (final id in pendingIds) {
      final match = localTasks.where((t) => t.id == id).toList();
      if (match.isEmpty) {
        await localDataSource.clearPendingSync(id);
        continue;
      }
      try {
        if (match.first.isLocalOnly) {
          await remoteDataSource.createTask(match.first);
        } else {
          await remoteDataSource.updateTask(match.first);
        }
        await localDataSource.clearPendingSync(id);
      } catch (e) {
        AppLogger.warning('Failed to sync task $id, will retry later: $e');
      }
    }
  }
}
