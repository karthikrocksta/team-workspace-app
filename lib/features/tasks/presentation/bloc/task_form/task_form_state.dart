part of 'task_form_bloc.dart';

abstract class TaskFormState extends Equatable {
  const TaskFormState();

  @override
  List<Object?> get props => [];
}

class TaskFormInitial extends TaskFormState {
  const TaskFormInitial();
}

class TaskFormSubmitting extends TaskFormState {
  const TaskFormSubmitting();
}

class TaskFormSuccess extends TaskFormState {
  final TaskEntity task;

  const TaskFormSuccess(this.task);

  @override
  List<Object?> get props => [task];
}

class TaskFormFailure extends TaskFormState {
  final String message;

  const TaskFormFailure(this.message);

  @override
  List<Object?> get props => [message];
}
