part of 'task_list_bloc.dart';

abstract class TaskListEvent extends Equatable {
  const TaskListEvent();

  @override
  List<Object?> get props => [];
}

/// Initial load or pull-to-refresh (resets to page 1).
class TaskListRefreshRequested extends TaskListEvent {
  const TaskListRefreshRequested();
}

/// Triggered by infinite-scroll when the user nears the end of the list.
class TaskListNextPageRequested extends TaskListEvent {
  const TaskListNextPageRequested();
}

class TaskListSearchChanged extends TaskListEvent {
  final String query;

  const TaskListSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class TaskListStatusFilterChanged extends TaskListEvent {
  final TaskStatus? status;

  const TaskListStatusFilterChanged(this.status);

  @override
  List<Object?> get props => [status];
}

class TaskListPriorityFilterChanged extends TaskListEvent {
  final TaskPriority? priority;

  const TaskListPriorityFilterChanged(this.priority);

  @override
  List<Object?> get props => [priority];
}

class TaskListFiltersCleared extends TaskListEvent {
  const TaskListFiltersCleared();
}

/// Dispatched by the Create/Edit flow so a new or changed task is reflected
/// on the dashboard immediately, without a full refetch or app restart.
class TaskListLocalTaskUpserted extends TaskListEvent {
  final TaskEntity task;

  const TaskListLocalTaskUpserted(this.task);

  @override
  List<Object?> get props => [task];
}
