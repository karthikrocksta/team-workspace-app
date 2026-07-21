import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/task_page.dart';
import '../repositories/task_repository.dart';

class GetTasksUseCase implements UseCase<TaskPage, GetTasksParams> {
  final TaskRepository repository;

  GetTasksUseCase(this.repository);

  @override
  Future<Either<Failure, TaskPage>> call(GetTasksParams params) {
    return repository.getTasks(page: params.page, pageSize: params.pageSize);
  }
}

class GetTasksParams extends Equatable {
  final int page;
  final int pageSize;

  const GetTasksParams({required this.page, required this.pageSize});

  @override
  List<Object?> get props => [page, pageSize];
}
