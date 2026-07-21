import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/task_entity.dart';
import '../../../domain/usecases/create_task_usecase.dart';
import '../../../domain/usecases/update_task_usecase.dart';

part 'task_form_event.dart';
part 'task_form_state.dart';

class TaskFormBloc extends Bloc<TaskFormEvent, TaskFormState> {
  final CreateTaskUseCase createTaskUseCase;
  final UpdateTaskUseCase updateTaskUseCase;

  TaskFormBloc({required this.createTaskUseCase, required this.updateTaskUseCase})
      : super(const TaskFormInitial()) {
    on<TaskFormSubmitted>(_onSubmitted);
  }

  Future<void> _onSubmitted(TaskFormSubmitted event, Emitter<TaskFormState> emit) async {
    emit(const TaskFormSubmitting());

    final result = event.isEditing
        ? await updateTaskUseCase(UpdateTaskParams(event.task))
        : await createTaskUseCase(CreateTaskParams(event.task));

    result.fold(
      (failure) => emit(TaskFormFailure(failure.message)),
      (task) => emit(TaskFormSuccess(task)),
    );
  }
}
