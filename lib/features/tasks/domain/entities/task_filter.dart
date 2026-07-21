import 'package:equatable/equatable.dart';
import 'task_entity.dart';

/// Groups the search query + status/priority filters that the dashboard
/// applies together, per the "Search and filters should work together"
/// requirement.
class TaskFilter extends Equatable {
  final String query;
  final TaskStatus? status;
  final TaskPriority? priority;

  const TaskFilter({this.query = '', this.status, this.priority});

  bool get isEmpty => query.isEmpty && status == null && priority == null;

  TaskFilter copyWith({
    String? query,
    TaskStatus? status,
    bool clearStatus = false,
    TaskPriority? priority,
    bool clearPriority = false,
  }) {
    return TaskFilter(
      query: query ?? this.query,
      status: clearStatus ? null : (status ?? this.status),
      priority: clearPriority ? null : (priority ?? this.priority),
    );
  }

  bool matches(TaskEntity task) {
    final matchesQuery = query.isEmpty || task.title.toLowerCase().contains(query.toLowerCase());
    final matchesStatus = status == null || task.status == status;
    final matchesPriority = priority == null || task.priority == priority;
    return matchesQuery && matchesStatus && matchesPriority;
  }

  @override
  List<Object?> get props => [query, status, priority];
}
