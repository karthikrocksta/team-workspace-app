import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';

class GetTaskByIdUseCase implements UseCase<TaskEntity, GetTaskByIdParams> {
  final TaskRepository repository;

  GetTaskByIdUseCase(this.repository);

  @override
  Future<Either<Failure, TaskEntity>> call(GetTaskByIdParams params) {
    return repository.getTaskById(params.id);
  }
}

class GetTaskByIdParams extends Equatable {
  final String id;

  const GetTaskByIdParams(this.id);

  @override
  List<Object?> get props => [id];
}
