part of 'task_detail_bloc.dart';

abstract class TaskDetailEvent extends Equatable {
  const TaskDetailEvent();

  @override
  List<Object?> get props => [];
}

class TaskDetailLoadRequested extends TaskDetailEvent {
  final String taskId;

  const TaskDetailLoadRequested(this.taskId);

  @override
  List<Object?> get props => [taskId];
}

/// Used when navigating from the dashboard with the task already in hand,
/// to render instantly while a fresh copy loads in the background.
class TaskDetailSeeded extends TaskDetailEvent {
  final TaskEntity task;

  const TaskDetailSeeded(this.task);

  @override
  List<Object?> get props => [task];
}

class TaskDetailStatusToggled extends TaskDetailEvent {
  const TaskDetailStatusToggled();
}
