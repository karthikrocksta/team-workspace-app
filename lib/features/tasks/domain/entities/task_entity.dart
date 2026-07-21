import 'package:equatable/equatable.dart';

enum TaskPriority { low, medium, high }

enum TaskStatus { pending, inProgress, completed }

extension TaskPriorityX on TaskPriority {
  String get label {
    switch (this) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
    }
  }
}

extension TaskStatusX on TaskStatus {
  String get label {
    switch (this) {
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completed:
        return 'Completed';
    }
  }
}

class TaskEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final TaskPriority priority;
  final DateTime dueDate;
  final TaskStatus status;
  final String assignedUser;
  final bool isLocalOnly;

  const TaskEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.dueDate,
    required this.status,
    required this.assignedUser,
    this.isLocalOnly = false,
  });

  TaskEntity copyWith({
    String? id,
    String? title,
    String? description,
    TaskPriority? priority,
    DateTime? dueDate,
    TaskStatus? status,
    String? assignedUser,
    bool? isLocalOnly,
  }) {
    return TaskEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      assignedUser: assignedUser ?? this.assignedUser,
      isLocalOnly: isLocalOnly ?? this.isLocalOnly,
    );
  }

  @override
  List<Object?> get props => [id, title, description, priority, dueDate, status, assignedUser, isLocalOnly];
}
