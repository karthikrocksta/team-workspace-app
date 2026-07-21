import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/task_entity.dart';
import '../entities/task_page.dart';

abstract class TaskRepository {
  /// Fetches a page of tasks. [page] is 1-indexed. When there's no
  /// connectivity, implementations fall back to the last cached page(s).
  Future<Either<Failure, TaskPage>> getTasks({required int page, required int pageSize});

  Future<Either<Failure, TaskEntity>> getTaskById(String id);

  Future<Either<Failure, TaskEntity>> createTask(TaskEntity task);

  Future<Either<Failure, TaskEntity>> updateTask(TaskEntity task);
}
