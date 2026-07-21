part of 'task_detail_bloc.dart';

abstract class TaskDetailState extends Equatable {
  const TaskDetailState();

  @override
  List<Object?> get props => [];
}

class TaskDetailLoading extends TaskDetailState {
  const TaskDetailLoading();
}

class TaskDetailLoaded extends TaskDetailState {
  final TaskEntity task;
  final bool isUpdating;

  const TaskDetailLoaded(this.task, {this.isUpdating = false});

  TaskDetailLoaded copyWith({TaskEntity? task, bool? isUpdating}) {
    return TaskDetailLoaded(task ?? this.task, isUpdating: isUpdating ?? this.isUpdating);
  }

  @override
  List<Object?> get props => [task, isUpdating];
}

class TaskDetailError extends TaskDetailState {
  final String message;

  const TaskDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
