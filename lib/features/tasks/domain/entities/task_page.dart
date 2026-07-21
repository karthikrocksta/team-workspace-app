import 'package:equatable/equatable.dart';
import 'task_entity.dart';

class TaskPage extends Equatable {
  final List<TaskEntity> tasks;
  final int total;
  final bool hasReachedMax;

  const TaskPage({required this.tasks, required this.total, required this.hasReachedMax});

  @override
  List<Object?> get props => [tasks, total, hasReachedMax];
}
