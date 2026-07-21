import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/task_entity.dart';
import '../../../domain/usecases/get_task_by_id_usecase.dart';
import '../../../domain/usecases/update_task_usecase.dart';

part 'task_detail_event.dart';
part 'task_detail_state.dart';

class TaskDetailBloc extends Bloc<TaskDetailEvent, TaskDetailState> {
  final GetTaskByIdUseCase getTaskByIdUseCase;
  final UpdateTaskUseCase updateTaskUseCase;

  TaskDetailBloc({required this.getTaskByIdUseCase, required this.updateTaskUseCase})
      : super(const TaskDetailLoading()) {
    on<TaskDetailLoadRequested>(_onLoadRequested);
    on<TaskDetailSeeded>(_onSeeded);
    on<TaskDetailStatusToggled>(_onStatusToggled);
  }

  Future<void> _onLoadRequested(TaskDetailLoadRequested event, Emitter<TaskDetailState> emit) async {
    emit(const TaskDetailLoading());
    final result = await getTaskByIdUseCase(GetTaskByIdParams(event.taskId));
    result.fold(
      (failure) => emit(TaskDetailError(failure.message)),
      (task) => emit(TaskDetailLoaded(task)),
    );
  }

  void _onSeeded(TaskDetailSeeded event, Emitter<TaskDetailState> emit) {
    emit(TaskDetailLoaded(event.task));
  }

  Future<void> _onStatusToggled(TaskDetailStatusToggled event, Emitter<TaskDetailState> emit) async {
    final current = state;
    if (current is! TaskDetailLoaded) return;

    final newStatus = current.task.status == TaskStatus.completed ? TaskStatus.pending : TaskStatus.completed;
    final updatedTask = current.task.copyWith(status: newStatus);

    emit(current.copyWith(task: updatedTask, isUpdating: true));

    final result = await updateTaskUseCase(UpdateTaskParams(updatedTask));
    result.fold(
      (failure) => emit(TaskDetailError(failure.message)),
      (task) => emit(TaskDetailLoaded(task)),
    );
  }
}
