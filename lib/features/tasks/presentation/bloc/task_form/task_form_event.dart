part of 'task_form_bloc.dart';

abstract class TaskFormEvent extends Equatable {
  const TaskFormEvent();

  @override
  List<Object?> get props => [];
}

class TaskFormSubmitted extends TaskFormEvent {
  final TaskEntity task;
  final bool isEditing;

  const TaskFormSubmitted({required this.task, required this.isEditing});

  @override
  List<Object?> get props => [task, isEditing];
}
