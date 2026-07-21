import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';

class UpdateTaskUseCase implements UseCase<TaskEntity, UpdateTaskParams> {
  final TaskRepository repository;

  UpdateTaskUseCase(this.repository);

  @override
  Future<Either<Failure, TaskEntity>> call(UpdateTaskParams params) {
    return repository.updateTask(params.task);
  }
}

class UpdateTaskParams extends Equatable {
  final TaskEntity task;

  const UpdateTaskParams(this.task);

  @override
  List<Object?> get props => [task];
}
