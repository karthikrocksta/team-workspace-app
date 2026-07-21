part of 'task_list_bloc.dart';

enum TaskListStatus { initial, loading, loadingMore, success, failure }

class TaskListState extends Equatable {
  final TaskListStatus status;
  final List<TaskEntity> allTasks; // unfiltered, as fetched from the repository
  final TaskFilter filter;
  final bool hasReachedMax;
  final int currentPage;
  final String? errorMessage;

  const TaskListState({
    this.status = TaskListStatus.initial,
    this.allTasks = const [],
    this.filter = const TaskFilter(),
    this.hasReachedMax = false,
    this.currentPage = 1,
    this.errorMessage,
  });

  /// The list actually rendered by the dashboard - search + filters applied
  /// together, per the requirements.
  List<TaskEntity> get visibleTasks => allTasks.where(filter.matches).toList();

  bool get isEmpty => status == TaskListStatus.success && visibleTasks.isEmpty;

  TaskListState copyWith({
    TaskListStatus? status,
    List<TaskEntity>? allTasks,
    TaskFilter? filter,
    bool? hasReachedMax,
    int? currentPage,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TaskListState(
      status: status ?? this.status,
      allTasks: allTasks ?? this.allTasks,
      filter: filter ?? this.filter,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, allTasks, filter, hasReachedMax, currentPage, errorMessage];
}
