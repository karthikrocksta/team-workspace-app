import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';

class CreateTaskUseCase implements UseCase<TaskEntity, CreateTaskParams> {
  final TaskRepository repository;

  CreateTaskUseCase(this.repository);

  @override
  Future<Either<Failure, TaskEntity>> call(CreateTaskParams params) {
    return repository.createTask(params.task);
  }
}

class CreateTaskParams extends Equatable {
  final TaskEntity task;

  const CreateTaskParams(this.task);

  @override
  List<Object?> get props => [task];
}
